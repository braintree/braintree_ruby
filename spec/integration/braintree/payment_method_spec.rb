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
end
