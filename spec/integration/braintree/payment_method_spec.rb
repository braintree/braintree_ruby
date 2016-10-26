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

    it "creates a payment method from a fake apple pay nonce" do
      customer = Braintree::Customer.create.customer
      token = SecureRandom.hex(16)
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => Braintree::Test::Nonce::ApplePayAmEx,
        :customer_id => customer.id,
        :token => token
      )

      result.should be_success
      apple_pay_card = result.payment_method
      apple_pay_card.should be_a(Braintree::ApplePayCard)
      apple_pay_card.should_not be_nil
      apple_pay_card.token.should == token
      apple_pay_card.card_type.should == Braintree::ApplePayCard::CardType::AmEx
      apple_pay_card.payment_instrument_name.should == "AmEx 41002"
      apple_pay_card.source_description.should == "AmEx 41002"
      apple_pay_card.default.should == true
      apple_pay_card.image_url.should =~ /apple_pay/
      apple_pay_card.expiration_month.to_i.should > 0
      apple_pay_card.expiration_year.to_i.should > 0
      apple_pay_card.customer_id.should == customer.id
    end

    it "creates a payment method from a fake android pay proxy card nonce" do
      customer = Braintree::Customer.create.customer
      token = SecureRandom.hex(16)
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => Braintree::Test::Nonce::AndroidPayDiscover,
        :customer_id => customer.id,
        :token => token
      )

      result.should be_success
      android_pay_card = result.payment_method
      android_pay_card.should be_a(Braintree::AndroidPayCard)
      android_pay_card.should_not be_nil
      android_pay_card.token.should == token
      android_pay_card.card_type.should == Braintree::CreditCard::CardType::Discover
      android_pay_card.virtual_card_type.should == Braintree::CreditCard::CardType::Discover
      android_pay_card.expiration_month.to_i.should > 0
      android_pay_card.expiration_year.to_i.should > 0
      android_pay_card.default.should == true
      android_pay_card.image_url.should =~ /android_pay/
      android_pay_card.source_card_type.should == Braintree::CreditCard::CardType::Visa
      android_pay_card.source_card_last_4.should == "1111"
      android_pay_card.google_transaction_id.should == "google_transaction_id"
      android_pay_card.source_description.should == "Visa 1111"
      android_pay_card.customer_id.should == customer.id
    end

    it "creates a payment method from a android pay network token nonce" do
      customer = Braintree::Customer.create.customer
      token = SecureRandom.hex(16)
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => Braintree::Test::Nonce::AndroidPayMasterCard,
        :customer_id => customer.id,
        :token => token
      )

      result.should be_success
      android_pay_card = result.payment_method
      android_pay_card.should be_a(Braintree::AndroidPayCard)
      android_pay_card.should_not be_nil
      android_pay_card.token.should == token
      android_pay_card.card_type.should == Braintree::CreditCard::CardType::MasterCard
      android_pay_card.virtual_card_type.should == Braintree::CreditCard::CardType::MasterCard
      android_pay_card.expiration_month.to_i.should > 0
      android_pay_card.expiration_year.to_i.should > 0
      android_pay_card.default.should == true
      android_pay_card.image_url.should =~ /android_pay/
      android_pay_card.source_card_type.should == Braintree::CreditCard::CardType::MasterCard
      android_pay_card.source_card_last_4.should == "4444"
      android_pay_card.google_transaction_id.should == "google_transaction_id"
      android_pay_card.source_description.should == "MasterCard 4444"
      android_pay_card.customer_id.should == customer.id
    end

    it "creates a payment method from an amex express checkout card nonce" do
      customer = Braintree::Customer.create.customer
      token = SecureRandom.hex(16)
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => Braintree::Test::Nonce::AmexExpressCheckout,
        :customer_id => customer.id,
        :token => token
      )

      result.should be_success
      amex_express_checkout_card = result.payment_method
      amex_express_checkout_card.should be_a(Braintree::AmexExpressCheckoutCard)
      amex_express_checkout_card.should_not be_nil

      amex_express_checkout_card.default.should == true
      amex_express_checkout_card.card_type.should == "American Express"
      amex_express_checkout_card.token.should == token
      amex_express_checkout_card.bin.should =~ /\A\d{6}\z/
      amex_express_checkout_card.expiration_month.should =~ /\A\d{2}\z/
      amex_express_checkout_card.expiration_year.should =~ /\A\d{4}\z/
      amex_express_checkout_card.card_member_number.should =~ /\A\d{4}\z/
      amex_express_checkout_card.card_member_expiry_date.should =~ /\A\d{2}\/\d{2}\z/
      amex_express_checkout_card.image_url.should include(".png")
      amex_express_checkout_card.source_description.should =~ /\AAmEx \d{4}\z/
      amex_express_checkout_card.customer_id.should == customer.id
    end

    it "creates a payment method from venmo account nonce" do
      customer = Braintree::Customer.create.customer
      token = SecureRandom.hex(16)
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => Braintree::Test::Nonce::VenmoAccount,
        :customer_id => customer.id,
        :token => token
      )

      result.should be_success
      venmo_account = result.payment_method
      venmo_account.should be_a(Braintree::VenmoAccount)

      venmo_account.default.should == true
      venmo_account.token.should == token
      venmo_account.username.should == "venmojoe"
      venmo_account.venmo_user_id.should == "Venmo-Joe-1"
      venmo_account.image_url.should include(".png")
      venmo_account.source_description.should == "Venmo Account: venmojoe"
      venmo_account.customer_id.should == customer.id
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

    it "respects verification amount when included outside of the nonce" do
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
          :verification_amount => "100.00"
        }
      )

      result.should_not be_success
      result.credit_card_verification.status.should == Braintree::Transaction::Status::ProcessorDeclined
      result.credit_card_verification.processor_response_code.should == "2000"
      result.credit_card_verification.processor_response_text.should == "Do Not Honor"
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

    it "allows passing a billing address id outside of the nonce" do
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

      address = Braintree::Address.create!(:customer_id => customer.id, :first_name => "Bobby", :last_name => "Tables")
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :billing_address_id => address.id
      )

      result.should be_success
      result.payment_method.should be_a(Braintree::CreditCard)
      token = result.payment_method.token

      found_credit_card = Braintree::CreditCard.find(token)
      found_credit_card.should_not be_nil
      found_credit_card.billing_address.first_name.should == "Bobby"
      found_credit_card.billing_address.last_name.should == "Tables"
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

    context "us bank account" do
      it "creates a payment method from a us bank account nonce" do
        customer = Braintree::Customer.create.customer
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => generate_valid_us_bank_account_nonce,
          :customer_id => customer.id
        )

        result.should be_success
        us_bank_account = result.payment_method
        us_bank_account.should be_a(Braintree::UsBankAccount)
        us_bank_account.routing_number.should == "123456789"
        us_bank_account.last_4.should == "1234"
        us_bank_account.account_type.should == "checking"
        us_bank_account.account_description.should == "PayPal Checking - 1234"
        us_bank_account.account_holder_name.should == "Dan Schulman"
        us_bank_account.bank_name.should == "UNKNOWN"
      end

      it "does not creates a payment method from an invalid us bank account nonce" do
        customer = Braintree::Customer.create.customer
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => generate_invalid_us_bank_account_nonce,
          :customer_id => customer.id
        )

        result.should_not be_success
        result.errors.for(:payment_method).on(:payment_method_nonce)[0].code.should == Braintree::ErrorCodes::PaymentMethod::PaymentMethodNonceUnknown
      end
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

      it "ignores passed billing address id" do
        nonce = nonce_for_paypal_account(:consent_code => "PAYPAL_CONSENT_CODE")
        customer = Braintree::Customer.create.customer
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
          :billing_address_id => "address_id"
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
        original_token = random_payment_method_token
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
        raw_client_token = Braintree::ClientToken.generate(:customer_id => customer.id, :sepa_mandate_type => Braintree::EuropeBankAccount::MandateType::Business)
        client_token = decode_client_token(raw_client_token)
        authorization_fingerprint = client_token["authorizationFingerprint"]
        http = ClientApiHttp.new(
          config,
          :authorization_fingerprint => authorization_fingerprint
        )

        nonce = http.create_europe_bank_account_nonce(
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
        result.payment_method.customer_id.should == customer.id
      end
    end

    context "Unknown payment methods" do
      it "creates an unknown payment method from a nonce" do
        customer = Braintree::Customer.create.customer
        token = SecureRandom.hex(16)
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => Braintree::Test::Nonce::AbstractTransactable,
          :customer_id => customer.id,
          :token => token
        )

        result.should be_success
        payment_method = result.payment_method
        payment_method.should_not be_nil
        payment_method.token.should == token
        payment_method.should be_a Braintree::UnknownPaymentMethod
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
        paypal_account.customer_id.should == customer.id
      end
    end

    context "apple pay cards" do
      it "finds the payment method with the given token" do
        customer = Braintree::Customer.create!
        payment_method_token = "PAYMENT_METHOD_TOKEN_#{rand(36**3).to_s(36)}"
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => Braintree::Test::Nonce::ApplePayAmEx,
          :customer_id => customer.id,
          :token => payment_method_token
        )
        result.should be_success

        apple_pay_card = Braintree::PaymentMethod.find(payment_method_token)
        apple_pay_card.should be_a(Braintree::ApplePayCard)
        apple_pay_card.should_not be_nil
        apple_pay_card.token.should == payment_method_token
        apple_pay_card.card_type.should == Braintree::ApplePayCard::CardType::AmEx
        apple_pay_card.default.should == true
        apple_pay_card.image_url.should =~ /apple_pay/
        apple_pay_card.expiration_month.to_i.should > 0
        apple_pay_card.expiration_year.to_i.should > 0
        apple_pay_card.source_description.should == "AmEx 41002"
        apple_pay_card.customer_id.should == customer.id
      end
    end

    context "android pay cards" do
      it "finds the proxy card payment method with the given token" do
        customer = Braintree::Customer.create!
        payment_method_token = "PAYMENT_METHOD_TOKEN_#{rand(36**3).to_s(36)}"
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => Braintree::Test::Nonce::AndroidPayDiscover,
          :customer_id => customer.id,
          :token => payment_method_token
        )
        result.should be_success

        android_pay_card = Braintree::PaymentMethod.find(payment_method_token)
        android_pay_card.should be_a(Braintree::AndroidPayCard)
        android_pay_card.should_not be_nil
        android_pay_card.token.should == payment_method_token
        android_pay_card.card_type.should == Braintree::CreditCard::CardType::Discover
        android_pay_card.virtual_card_type.should == Braintree::CreditCard::CardType::Discover
        android_pay_card.expiration_month.to_i.should > 0
        android_pay_card.expiration_year.to_i.should > 0
        android_pay_card.default.should == true
        android_pay_card.image_url.should =~ /android_pay/
        android_pay_card.source_card_type.should == Braintree::CreditCard::CardType::Visa
        android_pay_card.source_card_last_4.should == "1111"
        android_pay_card.google_transaction_id.should == "google_transaction_id"
        android_pay_card.source_description.should == "Visa 1111"
        android_pay_card.customer_id.should == customer.id
      end

      it "finds the network token payment method with the given token" do
        customer = Braintree::Customer.create!
        payment_method_token = "PAYMENT_METHOD_TOKEN_#{rand(36**3).to_s(36)}"
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => Braintree::Test::Nonce::AndroidPayMasterCard,
          :customer_id => customer.id,
          :token => payment_method_token
        )
        result.should be_success

        android_pay_card = Braintree::PaymentMethod.find(payment_method_token)
        android_pay_card.should be_a(Braintree::AndroidPayCard)
        android_pay_card.should_not be_nil
        android_pay_card.token.should == payment_method_token
        android_pay_card.card_type.should == Braintree::CreditCard::CardType::MasterCard
        android_pay_card.virtual_card_type.should == Braintree::CreditCard::CardType::MasterCard
        android_pay_card.expiration_month.to_i.should > 0
        android_pay_card.expiration_year.to_i.should > 0
        android_pay_card.default.should == true
        android_pay_card.image_url.should =~ /android_pay/
        android_pay_card.source_card_type.should == Braintree::CreditCard::CardType::MasterCard
        android_pay_card.source_card_last_4.should == "4444"
        android_pay_card.google_transaction_id.should == "google_transaction_id"
        android_pay_card.source_description.should == "MasterCard 4444"
        android_pay_card.customer_id.should == customer.id
      end
    end

    context "unknown payment methods" do
      it "finds the payment method with the given token" do
        customer = Braintree::Customer.create!
        payment_method_token = "FUTURE_PAYMENT_#{rand(36**3).to_s(36)}"
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => Braintree::Test::Nonce::AbstractTransactable,
          :customer_id => customer.id,
          :token => payment_method_token
        )
        result.should be_success

        payment_method = Braintree::PaymentMethod.find(payment_method_token)
        payment_method.should_not be_nil
        payment_method.token.should == payment_method_token
        payment_method.image_url.should_not be_nil
        payment_method.should be_a Braintree::UnknownPaymentMethod
        payment_method.customer_id.should == customer.id
      end
    end

    it "raises a NotFoundError exception if payment method cannot be found" do
      expect do
        Braintree::PaymentMethod.find("invalid-token")
      end.to raise_error(Braintree::NotFoundError, 'payment method with token "invalid-token" not found')
    end
  end

  describe "self.delete" do
    it "deletes an android pay card" do
      customer = Braintree::Customer.create!

      create_result = Braintree::PaymentMethod.create(
        :payment_method_nonce => Braintree::Test::Nonce::AndroidPayDiscover,
        :customer_id => customer.id
      )

      token = create_result.payment_method.token

      android_card = Braintree::PaymentMethod.find(token)
      android_card.should be_a(Braintree::AndroidPayCard)

      delete_result = Braintree::PaymentMethod.delete(token)
      delete_result.success?.should == true

      expect do
        Braintree::PaymentMethod.find(token)
      end.to raise_error(Braintree::NotFoundError)
    end

    it "deletes an apple pay card" do
      customer = Braintree::Customer.create!

      create_result = Braintree::PaymentMethod.create(
        :payment_method_nonce => Braintree::Test::Nonce::ApplePayAmEx,
        :customer_id => customer.id
      )
      token = create_result.payment_method.token

      apple_pay_card = Braintree::PaymentMethod.find(token)
      apple_pay_card.should be_a(Braintree::ApplePayCard)

      delete_result = Braintree::PaymentMethod.delete(token)
      delete_result.success?.should == true

      expect do
        Braintree::PaymentMethod.find(token)
      end.to raise_error(Braintree::NotFoundError)
    end

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
      result.success?.should == true

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

      result = Braintree::PaymentMethod.delete(token)
      result.success?.should == true

      expect do
        Braintree::PaymentMethod.find(token)
      end.to raise_error(Braintree::NotFoundError, "payment method with token \"#{token}\" not found")
    end

    it "raises a NotFoundError exception if payment method cannot be found" do
      token = "CREDIT_CARD_#{rand(36**3).to_s(36)}"
      customer = Braintree::Customer.create!

      expect do
        Braintree::PaymentMethod.delete(token)
      end.to raise_error(Braintree::NotFoundError)
    end
  end

  describe "self.update" do
    context "credit cards" do
      it "updates the credit card" do
        customer = Braintree::Customer.create!
        credit_card = Braintree::CreditCard.create!(
          :cardholder_name => "Original Holder",
          :customer_id => customer.id,
          :cvv => "123",
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2012"
        )
        update_result = Braintree::PaymentMethod.update(credit_card.token,
          :cardholder_name => "New Holder",
          :cvv => "456",
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "06/2013"
        )
        update_result.success?.should == true
        update_result.payment_method.should == credit_card
        updated_credit_card = update_result.payment_method
        updated_credit_card.cardholder_name.should == "New Holder"
        updated_credit_card.bin.should == Braintree::Test::CreditCardNumbers::MasterCard[0, 6]
        updated_credit_card.last_4.should == Braintree::Test::CreditCardNumbers::MasterCard[-4..-1]
        updated_credit_card.expiration_date.should == "06/2013"
      end

      context "billing address" do
        it "creates a new billing address by default" do
          customer = Braintree::Customer.create!
          credit_card = Braintree::CreditCard.create!(
            :customer_id => customer.id,
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2012",
            :billing_address => {
              :street_address => "123 Nigeria Ave"
            }
          )
          update_result = Braintree::PaymentMethod.update(credit_card.token,
            :billing_address => {
              :region => "IL"
            }
          )
          update_result.success?.should == true
          updated_credit_card = update_result.payment_method
          updated_credit_card.billing_address.region.should == "IL"
          updated_credit_card.billing_address.street_address.should == nil
          updated_credit_card.billing_address.id.should_not == credit_card.billing_address.id
        end

        it "updates the billing address if option is specified" do
          customer = Braintree::Customer.create!
          credit_card = Braintree::CreditCard.create!(
            :customer_id => customer.id,
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2012",
            :billing_address => {
              :street_address => "123 Nigeria Ave"
            }
          )
          update_result = Braintree::PaymentMethod.update(credit_card.token,
            :billing_address => {
              :region => "IL",
              :options => {:update_existing => true}
            }
          )
          update_result.success?.should == true
          updated_credit_card = update_result.payment_method
          updated_credit_card.billing_address.region.should == "IL"
          updated_credit_card.billing_address.street_address.should == "123 Nigeria Ave"
          updated_credit_card.billing_address.id.should == credit_card.billing_address.id
        end

        it "updates the country via codes" do
          customer = Braintree::Customer.create!
          credit_card = Braintree::CreditCard.create!(
            :customer_id => customer.id,
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2012",
            :billing_address => {
              :street_address => "123 Nigeria Ave"
            }
          )
          update_result = Braintree::PaymentMethod.update(credit_card.token,
            :billing_address => {
              :country_name => "American Samoa",
              :country_code_alpha2 => "AS",
              :country_code_alpha3 => "ASM",
              :country_code_numeric => "016",
              :options => {:update_existing => true}
            }
          )
          update_result.success?.should == true
          updated_credit_card = update_result.payment_method
          updated_credit_card.billing_address.country_name.should == "American Samoa"
          updated_credit_card.billing_address.country_code_alpha2.should == "AS"
          updated_credit_card.billing_address.country_code_alpha3.should == "ASM"
          updated_credit_card.billing_address.country_code_numeric.should == "016"
        end
      end

      it "can pass expiration_month and expiration_year" do
        customer = Braintree::Customer.create!
        credit_card = Braintree::CreditCard.create!(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2012"
        )
        update_result = Braintree::PaymentMethod.update(credit_card.token,
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_month => "07",
          :expiration_year => "2011"
        )
        update_result.success?.should == true
        update_result.payment_method.should == credit_card
        update_result.payment_method.expiration_month.should == "07"
        update_result.payment_method.expiration_year.should == "2011"
        update_result.payment_method.expiration_date.should == "07/2011"
      end

      it "verifies the update if options[verify_card]=true" do
        customer = Braintree::Customer.create!
        credit_card = Braintree::CreditCard.create!(
          :cardholder_name => "Original Holder",
          :customer_id => customer.id,
          :cvv => "123",
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2012"
        )
        update_result = Braintree::PaymentMethod.update(credit_card.token,
          :cardholder_name => "New Holder",
          :cvv => "456",
          :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::MasterCard,
          :expiration_date => "06/2013",
          :options => {:verify_card => true}
        )
        update_result.success?.should == false
        update_result.credit_card_verification.status.should == Braintree::Transaction::Status::ProcessorDeclined
        update_result.credit_card_verification.gateway_rejection_reason.should be_nil
      end

      it "can update the billing address" do
        customer = Braintree::Customer.create!
        credit_card = Braintree::CreditCard.create!(
          :cardholder_name => "Original Holder",
          :customer_id => customer.id,
          :cvv => "123",
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2012",
          :billing_address => {
            :first_name => "Old First Name",
            :last_name => "Old Last Name",
            :company => "Old Company",
            :street_address => "123 Old St",
            :extended_address => "Apt Old",
            :locality => "Old City",
            :region => "Old State",
            :postal_code => "12345",
            :country_name => "Canada"
          }
        )
        result = Braintree::PaymentMethod.update(credit_card.token,
          :options => {:verify_card => false},
          :billing_address => {
            :first_name => "New First Name",
            :last_name => "New Last Name",
            :company => "New Company",
            :street_address => "123 New St",
            :extended_address => "Apt New",
            :locality => "New City",
            :region => "New State",
            :postal_code => "56789",
            :country_name => "United States of America"
          }
        )
        result.success?.should == true
        address = result.payment_method.billing_address
        address.first_name.should == "New First Name"
        address.last_name.should == "New Last Name"
        address.company.should == "New Company"
        address.street_address.should == "123 New St"
        address.extended_address.should == "Apt New"
        address.locality.should == "New City"
        address.region.should == "New State"
        address.postal_code.should == "56789"
        address.country_name.should == "United States of America"
      end

      it "returns an error response if invalid" do
        customer = Braintree::Customer.create!
        credit_card = Braintree::CreditCard.create!(
          :cardholder_name => "Original Holder",
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2012"
        )
        update_result = Braintree::PaymentMethod.update(credit_card.token,
          :cardholder_name => "New Holder",
          :number => "invalid",
          :expiration_date => "05/2014"
        )
        update_result.success?.should == false
        update_result.errors.for(:credit_card).on(:number)[0].message.should == "Credit card number must be 12-19 digits."
      end

      it "can update the default" do
        customer = Braintree::Customer.create!
        card1 = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        ).credit_card
        card2 = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        ).credit_card

        card1.should be_default
        card2.should_not be_default

        Braintree::PaymentMethod.update(card2.token, :options => {:make_default => true})

        Braintree::CreditCard.find(card1.token).should_not be_default
        Braintree::CreditCard.find(card2.token).should be_default
      end
    end

    context "coinbase accounts" do
      it "can make a coinbase account the default payment method" do
        customer = Braintree::Customer.create!
        result = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009",
          :options => {:make_default => true}
        )
        result.should be_success

        nonce = Braintree::Test::Nonce::Coinbase
        original_token = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id
        ).payment_method.token

        updated_result = Braintree::PaymentMethod.update(
          original_token,
          :options => {:make_default => true}
        )

        updated_customer = Braintree::Customer.find(customer.id)
        updated_customer.default_payment_method.token.should == original_token
      end
    end

    context "paypal accounts" do
      it "updates a paypal account's token" do
        customer = Braintree::Customer.create!
        original_token = random_payment_method_token
        nonce = nonce_for_paypal_account(
          :consent_code => "consent-code",
          :token => original_token
        )
        original_result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id
        )

        updated_token = "UPDATED_TOKEN-" + rand(36**3).to_s(36)
        updated_result = Braintree::PaymentMethod.update(
          original_token,
          :token => updated_token
        )

        updated_paypal_account = Braintree::PayPalAccount.find(updated_token)
        updated_paypal_account.email.should == original_result.payment_method.email

        expect do
          Braintree::PayPalAccount.find(original_token)
        end.to raise_error(Braintree::NotFoundError, "payment method with token \"#{original_token}\" not found")
      end

      it "can make a paypal account the default payment method" do
        customer = Braintree::Customer.create!
        result = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009",
          :options => {:make_default => true}
        )
        result.should be_success

        nonce = nonce_for_paypal_account(:consent_code => "consent-code")
        original_token = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id
        ).payment_method.token

        updated_result = Braintree::PaymentMethod.update(
          original_token,
          :options => {:make_default => true}
        )

        updated_paypal_account = Braintree::PayPalAccount.find(original_token)
        updated_paypal_account.should be_default
      end

      it "returns an error if a token for account is used to attempt an update" do
        customer = Braintree::Customer.create!
        first_token = random_payment_method_token
        second_token = random_payment_method_token

        first_nonce = nonce_for_paypal_account(
          :consent_code => "consent-code",
          :token => first_token
        )
        first_result = Braintree::PaymentMethod.create(
          :payment_method_nonce => first_nonce,
          :customer_id => customer.id
        )

        second_nonce = nonce_for_paypal_account(
          :consent_code => "consent-code",
          :token => second_token
        )
        second_result = Braintree::PaymentMethod.create(
          :payment_method_nonce => second_nonce,
          :customer_id => customer.id
        )

        updated_result = Braintree::PaymentMethod.update(
          first_token,
          :token => second_token
        )

        updated_result.should_not be_success
        updated_result.errors.first.code.should == "92906"
      end
    end
  end

  context "payment method grant and revoke" do
    before(:each) do
      partner_merchant_gateway = Braintree::Gateway.new(
        :merchant_id => "integration_merchant_public_id",
        :public_key => "oauth_app_partner_user_public_key",
        :private_key => "oauth_app_partner_user_private_key",
        :environment => Braintree::Configuration.environment,
        :logger => Logger.new("/dev/null")
      )
      customer = partner_merchant_gateway.customer.create(
        :first_name => "Joe",
        :last_name => "Brown",
        :company => "ExampleCo",
        :email => "joe@example.com",
        :phone => "312.555.1234",
        :fax => "614.555.5678",
        :website => "www.example.com"
      ).customer
      @credit_card = partner_merchant_gateway.credit_card.create(
        :customer_id => customer.id,
        :cardholder_name => "Adam Davis",
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2009"
      ).credit_card

      oauth_gateway = Braintree::Gateway.new(
        :client_id => "client_id$#{Braintree::Configuration.environment}$integration_client_id",
        :client_secret => "client_secret$#{Braintree::Configuration.environment}$integration_client_secret",
        :logger => Logger.new("/dev/null")
      )
      access_token = Braintree::OAuthTestHelper.create_token(oauth_gateway, {
        :merchant_public_id => "integration_merchant_id",
        :scope => "grant_payment_method"
      }).credentials.access_token

      @granting_gateway = Braintree::Gateway.new(
        :access_token => access_token,
        :logger => Logger.new("/dev/null")
      )
    end

    describe "self.grant" do
      it "returns an error result when the grant doesn't succeed" do
        grant_result = @granting_gateway.payment_method.grant("payment_method_from_grant", true)
        grant_result.should_not be_success
      end

      it "returns a nonce that is transactable by a partner merchant exactly once" do
        grant_result = @granting_gateway.payment_method.grant(@credit_card.token, :allow_vaulting => false)
        grant_result.should be_success

        result = Braintree::Transaction.sale(
          :payment_method_nonce => grant_result.payment_method_nonce.nonce,
          :amount => Braintree::Test::TransactionAmounts::Authorize
        )
        result.should be_success

        result2 = Braintree::Transaction.sale(
          :payment_method_nonce => grant_result.payment_method_nonce.nonce,
          :amount => Braintree::Test::TransactionAmounts::Authorize
        )
        result2.should_not be_success
      end

      it "returns a nonce that is not vaultable" do
        grant_result = @granting_gateway.payment_method.grant(@credit_card.token, false)

        customer_result = Braintree::Customer.create()

        result = Braintree::PaymentMethod.create(
          :customer_id => customer_result.customer.id,
          :payment_method_nonce => grant_result.payment_method_nonce.nonce
        )
        result.should_not be_success
      end

      it "returns a nonce that is vaultable" do
        grant_result = @granting_gateway.payment_method.grant(@credit_card.token, :allow_vaulting => true)

        customer_result = Braintree::Customer.create()

        result = Braintree::PaymentMethod.create(
          :customer_id => customer_result.customer.id,
          :payment_method_nonce => grant_result.payment_method_nonce.nonce
        )
        result.should be_success
      end

      it "raises an error if the token isn't found" do
        expect do
          @granting_gateway.payment_method.grant("not_a_real_token", false)
        end.to raise_error
      end

      it "returns a valid nonce with no options set" do
        expect do
          grant_result = @granting_gateway.payment_method.grant(@credit_card.token)
          grant_result.should be_success
        end
      end
    end

    describe "self.revoke" do
      it "raises an error if the token isn't found" do
        expect do
          @granting_gateway.payment_method.revoke("not_a_real_token")
        end.to raise_error
      end

      it "renders a granted nonce useless" do
        grant_result = @granting_gateway.payment_method.grant(@credit_card.token)
        revoke_result = @granting_gateway.payment_method.revoke(@credit_card.token)
        revoke_result.should be_success

        customer_result = Braintree::Customer.create()

        result = Braintree::PaymentMethod.create(
          :customer_id => customer_result.customer.id,
          :payment_method_nonce => grant_result.payment_method_nonce.nonce
        )
        result.should_not be_success
      end

      it "renders a granted nonce obtained uisng options hash, useless" do
        grant_result = @granting_gateway.payment_method.grant(@credit_card.token, :allow_vaulting => true)
        revoke_result = @granting_gateway.payment_method.revoke(@credit_card.token)
        revoke_result.should be_success

        customer_result = Braintree::Customer.create()

        result = Braintree::PaymentMethod.create(
          :customer_id => customer_result.customer.id,
          :payment_method_nonce => grant_result.payment_method_nonce.nonce
        )
        result.should_not be_success
      end
    end
  end
end
