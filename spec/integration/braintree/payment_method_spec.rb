require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::PaymentMethod do
  describe "self.create" do
    it "creates a payment method from a vaulted credit card nonce" do
      config = Braintree::Configuration.instantiate
      customer = Braintree::Customer.create.customer
      client_token = Braintree::ClientToken.generate(:customer_id => customer.id)
      authorization_fingerprint = JSON.parse(client_token)["authorizationFingerprint"]
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
      client_token = Braintree::ClientToken.generate(:customer_id => customer.id)
      authorization_fingerprint = JSON.parse(client_token)["authorizationFingerprint"]
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

    context "paypal" do
      it "creates a payment method from an unvalidated future paypal account nonce" do
        with_altpay_merchant do
          config = Braintree::Configuration.instantiate
          customer = Braintree::Customer.create.customer
          client_token = Braintree::ClientToken.generate
          authorization_fingerprint = JSON.parse(client_token)["authorizationFingerprint"]
          http = ClientApiHttp.new(
            config,
            :authorization_fingerprint => authorization_fingerprint,
          )

          response = http.create_paypal_account(
            :consent_code => "PAYPAL_CONSENT_CODE"
          )
          response.code.should == "202"

          nonce = JSON.parse(response.body)["paypalAccounts"].first["nonce"]
          result = Braintree::PaymentMethod.create(
            :payment_method_nonce => nonce,
            :customer_id => customer.id
          )

          result.should be_success
          result.payment_method.should be_a(Braintree::PayPalAccount)
          token = result.payment_method.token

          found_paypal_account = Braintree::PayPalAccount.find(token)
          found_paypal_account.should_not be_nil
        end
      end

      it "does not create a payment method from an unvalidated onetime paypal account nonce" do
        with_altpay_merchant do
          config = Braintree::Configuration.instantiate
          customer = Braintree::Customer.create.customer
          client_token = Braintree::ClientToken.generate
          authorization_fingerprint = JSON.parse(client_token)["authorizationFingerprint"]
          http = ClientApiHttp.new(
            config,
            :authorization_fingerprint => authorization_fingerprint,
          )

          response = http.create_paypal_account(
            :access_token => "PAYPAL_ACCESS_TOKEN",
          )
          response.code.should == "202"

          nonce = JSON.parse(response.body)["paypalAccounts"].first["nonce"]
          result = Braintree::PaymentMethod.create(
            :payment_method_nonce => nonce,
            :customer_id => customer.id
          )

          result.should_not be_success
          result.errors.first.message.should == "Consent code is required for vaulting."
          result.errors.first.code.should == "82902"
        end
      end

      it "returns appropriate validation errors" do
        with_altpay_merchant do
          config = Braintree::Configuration.instantiate
          customer = Braintree::Customer.create.customer
          client_token = Braintree::ClientToken.generate
          authorization_fingerprint = JSON.parse(client_token)["authorizationFingerprint"]
          http = ClientApiHttp.new(
            config,
            :authorization_fingerprint => authorization_fingerprint,
          )

          response = http.create_paypal_account(
            :token => "PAYPAL_TOKEN",
          )
          response.code.should == "202"

          nonce = JSON.parse(response.body)["paypalAccounts"].first["nonce"]
          result = Braintree::PaymentMethod.create(
            :payment_method_nonce => nonce,
            :customer_id => customer.id
          )

          result.should_not be_success
          errors = result.errors.map(&:code)
          errors.should include("82901")
          errors.should include("82902")
        end
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
        with_altpay_merchant do
          config = Braintree::Configuration.instantiate
          customer = Braintree::Customer.create!
          payment_method_token = "paypal-account-#{Time.now.to_i}"
          client_token = Braintree::ClientToken.generate
          authorization_fingerprint = JSON.parse(client_token)["authorizationFingerprint"]
          http = ClientApiHttp.new(
            config,
            :authorization_fingerprint => authorization_fingerprint,
          )

          response = http.create_paypal_account(
            :consent_code => "consent-code",
            :token => payment_method_token,
          )
          response.code.should == "202"

          nonce = JSON.parse(response.body)["paypalAccounts"].first["nonce"]

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
    end

    it "raises a NotFoundError exception if payment method cannot be found" do
      expect do
        Braintree::PaymentMethod.find("invalid-token")
      end.to raise_error(Braintree::NotFoundError, 'payment method with token "invalid-token" not found')
    end
  end

  describe "self.delete" do
    it "deletes a paypal account" do
      with_altpay_merchant do
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
    end

    it "deletes a credit card" do
      token = "CREDIT_CARD_#{rand(36**3).to_s(36)}"
      customer = Braintree::Customer.create!
      nonce = nonce_for_new_credit_card({
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
