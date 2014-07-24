require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::PaymentMethod do
  describe "self.create" do
    it "creates a payment method from a vaulted credit card nonce" do
      config = Braintree::Configuration.instantiate
      customer = Braintree::Customer.create.customer
      raw_client_token = Braintree::ClientToken.generate(:customer_id => customer.id)
      client_token = decode_client_token(raw_client_token)
      authorization_fingerprint = client_token["authorizationFingerprint"]
      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => authorization_fingerprint,
        :shared_customer_identifier => "fake_identifier",
        :shared_customer_identifier_type => "testing"
      )

      response = http.create_credit_card(
        :number => 4111111111111111,
        :expirationMonth => 12,
        :expirationYear => 2020
      )
      response.code.should == "201"

      nonce = JSON.parse(response.body)["creditCards"].first["nonce"]
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id
      )

      result.should be_success
      result.payment_method.should be_a(Braintree::CreditCard)
      token = result.payment_method.token

      found_credit_card = Braintree::CreditCard.find(token)
      found_credit_card.should_not be_nil
    end

    it "creates a payment method from an unvalidated credit card nonce" do
      config = Braintree::Configuration.instantiate
      customer = Braintree::Customer.create.customer
      raw_client_token = Braintree::ClientToken.generate(:customer_id => customer.id)
      client_token = decode_client_token(raw_client_token)
      authorization_fingerprint = client_token["authorizationFingerprint"]
      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => authorization_fingerprint,
        :shared_customer_identifier => "fake_identifier",
        :shared_customer_identifier_type => "testing"
      )

      response = http.create_credit_card(
        :number => "4111111111111111",
        :expirationMonth => "12",
        :expirationYear => "2020",
        :options => {:validate => false}
      )
      response.code.should == "202"

      nonce = JSON.parse(response.body)["creditCards"].first["nonce"]
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id
      )

      result.should be_success
      result.payment_method.should be_a(Braintree::CreditCard)
      token = result.payment_method.token

      found_credit_card = Braintree::CreditCard.find(token)
      found_credit_card.should_not be_nil
    end

    it "allows passing the make_default option alongside the nonce" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2009",
        :cvv => "100"
      )
      result.success?.should == true
      original_payment_method = result.credit_card
      original_payment_method.should be_default

      nonce = nonce_for_paypal_account(:consent_code => "PAYPAL_CONSENT_CODE")
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :options => {:make_default => true}
      )

      result.should be_success
      new_payment_method = result.payment_method
      new_payment_method.should be_default
    end

    it "overrides the token in the nonce" do
      customer = Braintree::Customer.create!

      first_token = "FIRST_TOKEN_#{rand(36**3).to_s(36)}"
      second_token = "SECOND_TOKEN_#{rand(36**3).to_s(36)}"
      nonce = nonce_for_paypal_account(
        :consent_code => "PAYPAL_CONSENT_CODE",
        :token => first_token
      )
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :token => second_token
      )

      result.should be_success
      payment_method = result.payment_method
      payment_method.token.should ==  second_token
    end

    it "respects verify_card and verification_merchant_account_id when included outside of the nonce" do
      nonce = nonce_for_new_payment_method(
        :credit_card => {
          :number => "4000111111111115",
          :expiration_month => "11",
          :expiration_year => "2099",
        }
      )
      customer = Braintree::Customer.create!
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :options => {
          :verify_card => true,
          :verification_merchant_account_id => SpecHelper::NonDefaultMerchantAccountId
        }
      )

      result.should_not be_success
      result.credit_card_verification.status.should == Braintree::Transaction::Status::ProcessorDeclined
      result.credit_card_verification.processor_response_code.should == "2000"
      result.credit_card_verification.processor_response_text.should == "Do Not Honor"
      result.credit_card_verification.merchant_account_id.should == SpecHelper::NonDefaultMerchantAccountId
    end

    it "respects fail_on_duplicate_payment_method when included outside of the nonce" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2012"
      )
      result.should be_success

      nonce = nonce_for_new_payment_method(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2012"
        }
      )
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :options => {
          :fail_on_duplicate_payment_method => true
        }
      )

      result.should_not be_success
      result.errors.first.code.should == "81724"
    end

    it "allows passing the billing address outside of the nonce" do
      config = Braintree::Configuration.instantiate
      customer = Braintree::Customer.create.customer
      raw_client_token = Braintree::ClientToken.generate(:customer_id => customer.id)
      client_token = decode_client_token(raw_client_token)
      authorization_fingerprint = client_token["authorizationFingerprint"]
      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => authorization_fingerprint,
        :shared_customer_identifier => "fake_identifier",
        :shared_customer_identifier_type => "testing"
      )

      response = http.create_credit_card(
        :number => "4111111111111111",
        :expirationMonth => "12",
        :expirationYear => "2020",
        :options => {:validate => false}
      )
      response.code.should == "202"

      nonce = JSON.parse(response.body)["creditCards"].first["nonce"]
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :billing_address => {
          :street_address => "123 Abc Way"
        }
      )

      result.should be_success
      result.payment_method.should be_a(Braintree::CreditCard)
      token = result.payment_method.token

      found_credit_card = Braintree::CreditCard.find(token)
      found_credit_card.should_not be_nil
      found_credit_card.billing_address.street_address.should == "123 Abc Way"
    end

    it "overrides the billing address in the nonce" do
      config = Braintree::Configuration.instantiate
      customer = Braintree::Customer.create.customer
      raw_client_token = Braintree::ClientToken.generate(:customer_id => customer.id)
      client_token = decode_client_token(raw_client_token)
      authorization_fingerprint = client_token["authorizationFingerprint"]
      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => authorization_fingerprint,
        :shared_customer_identifier => "fake_identifier",
        :shared_customer_identifier_type => "testing"
      )

      response = http.create_credit_card(
        :number => "4111111111111111",
        :expirationMonth => "12",
        :expirationYear => "2020",
        :options => {:validate => false},
        :billing_address => {
          :street_address => "456 Xyz Way"
        }
      )
      response.code.should == "202"

      nonce = JSON.parse(response.body)["creditCards"].first["nonce"]
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :billing_address => {
          :street_address => "123 Abc Way"
        }
      )

      result.should be_success
      result.payment_method.should be_a(Braintree::CreditCard)
      token = result.payment_method.token

      found_credit_card = Braintree::CreditCard.find(token)
      found_credit_card.should_not be_nil
      found_credit_card.billing_address.street_address.should == "123 Abc Way"
    end

    it "does not override the billing address for a vaulted credit card" do
      config = Braintree::Configuration.instantiate
      customer = Braintree::Customer.create.customer
      raw_client_token = Braintree::ClientToken.generate(:customer_id => customer.id)
      client_token = decode_client_token(raw_client_token)
      authorization_fingerprint = client_token["authorizationFingerprint"]
      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => authorization_fingerprint,
        :shared_customer_identifier => "fake_identifier",
        :shared_customer_identifier_type => "testing"
      )

      response = http.create_credit_card(
        :number => 4111111111111111,
        :expirationMonth => 12,
        :expirationYear => 2020,
        :billing_address => {
          :street_address => "456 Xyz Way"
        }
      )
      response.code.should == "201"

      nonce = JSON.parse(response.body)["creditCards"].first["nonce"]
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :billing_address => {
          :street_address => "123 Abc Way"
        }
      )

      result.should be_success
      result.payment_method.should be_a(Braintree::CreditCard)
      token = result.payment_method.token

      found_credit_card = Braintree::CreditCard.find(token)
      found_credit_card.should_not be_nil
      found_credit_card.billing_address.street_address.should == "456 Xyz Way"
    end

    context "paypal" do
      it "creates a payment method from an unvalidated future paypal account nonce" do
        nonce = nonce_for_paypal_account(:consent_code => "PAYPAL_CONSENT_CODE")
        customer = Braintree::Customer.create.customer
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id
        )

        result.should be_success
        result.payment_method.should be_a(Braintree::PayPalAccount)
        result.payment_method.image_url.should_not be_nil
        token = result.payment_method.token

        found_paypal_account = Braintree::PayPalAccount.find(token)
        found_paypal_account.should_not be_nil
      end

      it "does not create a payment method from an unvalidated onetime paypal account nonce" do
        customer = Braintree::Customer.create.customer
        nonce = nonce_for_paypal_account(:access_token => "PAYPAL_ACCESS_TOKEN")
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id
        )

        result.should_not be_success
        result.errors.first.code.should == "82902"
      end

      it "ignores passed billing address params" do
        nonce = nonce_for_paypal_account(:consent_code => "PAYPAL_CONSENT_CODE")
        customer = Braintree::Customer.create.customer
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
          :billing_address => {
            :street_address => "123 Abc Way"
          }
        )

        result.should be_success
        result.payment_method.should be_a(Braintree::PayPalAccount)
        result.payment_method.image_url.should_not be_nil
        token = result.payment_method.token

        found_paypal_account = Braintree::PayPalAccount.find(token)
        found_paypal_account.should_not be_nil
      end

      it "returns appropriate validation errors" do
        customer = Braintree::Customer.create.customer
        nonce = nonce_for_paypal_account(:token => "PAYPAL_TOKEN")
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id
        )

        result.should_not be_success
        errors = result.errors.map(&:code)
        errors.should include("82901")
        errors.should include("82902")
      end

      it "doesn't return an error if credit card options are present for a paypal nonce" do
        customer = Braintree::Customer.create!
        original_token = "paypal-account-#{Time.now.to_i}"
        nonce = nonce_for_paypal_account(
          :consent_code => "consent-code",
          :token => original_token
        )

        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
          :options => {
            :verify_card => true,
            :fail_on_duplicate_payment_method => true,
            :verification_merchant_account_id => "not_a_real_merchant_account_id"
          }
        )

        result.should be_success
      end
    end

    context "SEPA" do
      it "returns the SEPA bank account behind the nonce" do
        config = Braintree::Configuration.instantiate
        customer = Braintree::Customer.create.customer
        raw_client_token = Braintree::ClientToken.generate(:customer_id => customer.id, :sepa_mandate_type => Braintree::SEPABankAccount::MandateType::Business)
        client_token = decode_client_token(raw_client_token)
        authorization_fingerprint = client_token["authorizationFingerprint"]
        http = ClientApiHttp.new(
          config,
          :authorization_fingerprint => authorization_fingerprint
        )

        nonce = http.create_sepa_bank_account_nonce(
          :accountHolderName => "Bob Holder",
          :iban => "DE89370400440532013000",
          :bic => "DEUTDEFF",
          :locale => "en-US",
          :billingAddress =>  {
            :region => "Hesse",
            :country_name => "Germany"
          }
        )
        nonce.should_not == nil
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id
        )

        result.should be_success
        result.payment_method.token.should_not == nil
        result.payment_method.image_url.should_not be_nil
      end
    end
  end

  describe "self.find" do
    context "credit cards" do
      it "finds the payment method with the given token" do
        customer = Braintree::Customer.create.customer
        result = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2012"
        )
        result.success?.should == true

        credit_card = Braintree::PaymentMethod.find(result.credit_card.token)
        credit_card.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
        credit_card.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
        credit_card.token.should == result.credit_card.token
        credit_card.expiration_date.should == "05/2012"
      end

      it "returns associated subscriptions with the credit card" do
        customer = Braintree::Customer.create.customer
        credit_card = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2012"
        ).credit_card

        subscription = Braintree::Subscription.create(
          :payment_method_token => credit_card.token,
          :plan_id => "integration_trialless_plan",
          :price => "1.00"
        ).subscription

        found_card = Braintree::PaymentMethod.find(credit_card.token)
        found_card.subscriptions.first.id.should == subscription.id
        found_card.subscriptions.first.plan_id.should == "integration_trialless_plan"
        found_card.subscriptions.first.payment_method_token.should == credit_card.token
        found_card.subscriptions.first.price.should == BigDecimal.new("1.00")
      end
    end

    context "paypal accounts" do
      it "finds the payment method with the given token" do
        customer = Braintree::Customer.create!
        payment_method_token = "PAYMENT_METHOD_TOKEN_#{rand(36**3).to_s(36)}"
        nonce = nonce_for_paypal_account(
          :consent_code => "consent-code",
          :token => payment_method_token
        )
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id
        )
        result.should be_success

        paypal_account = Braintree::PaymentMethod.find(payment_method_token)
        paypal_account.should be_a(Braintree::PayPalAccount)
        paypal_account.token.should == payment_method_token
        paypal_account.email.should == "jane.doe@example.com"
      end
    end

    it "raises a NotFoundError exception if payment method cannot be found" do
      expect do
        Braintree::PaymentMethod.find("invalid-token")
      end.to raise_error(Braintree::NotFoundError, 'payment method with token "invalid-token" not found')
    end
  end

  describe "self.delete" do
    it "deletes a paypal account" do
      customer = Braintree::Customer.create!
      paypal_account_token = "PAYPAL_ACCOUNT_TOKEN_#{rand(36**3).to_s(36)}"
      nonce = nonce_for_paypal_account(
        :consent_code => "PAYPAL_CONSENT_CODE",
        :token => paypal_account_token
      )
      Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id
      )

      paypal_account = Braintree::PaymentMethod.find(paypal_account_token)
      paypal_account.should be_a(Braintree::PayPalAccount)

      result = Braintree::PaymentMethod.delete(paypal_account_token)

      expect do
        Braintree::PaymentMethod.find(paypal_account_token)
      end.to raise_error(Braintree::NotFoundError, "payment method with token \"#{paypal_account_token}\" not found")
    end

    it "deletes a credit card" do
      token = "CREDIT_CARD_#{rand(36**3).to_s(36)}"
      customer = Braintree::Customer.create!
      nonce = nonce_for_new_payment_method({
        :credit_card => {
          :number => "4111111111111111",
          :expiration_month => "11",
          :expiration_year => "2099",
          :token => token
        },
        :client_token_options => {:customer_id => customer.id}
      })

      Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id
      )

      Braintree::PaymentMethod.delete(token)

      expect do
        Braintree::PaymentMethod.find(token)
      end.to raise_error(Braintree::NotFoundError, "payment method with token \"#{token}\" not found")
    end
  end
end
