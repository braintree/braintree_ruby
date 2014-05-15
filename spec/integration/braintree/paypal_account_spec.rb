require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::PayPalAccount do
  describe "self.find" do
    it "returns a PayPalAccount" do
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

        paypal_account = Braintree::PayPalAccount.find(payment_method_token)
        paypal_account.should be_a(Braintree::PayPalAccount)
        paypal_account.token.should == payment_method_token
        paypal_account.email.should == "jane.doe@example.com"
      end
    end

    it "raises if the payment method token is not found" do
      with_altpay_merchant do
        expect do
          Braintree::PayPalAccount.find("nonexistant-paypal-account")
        end.to raise_error(Braintree::NotFoundError)
      end
    end

    it "does not return a different payment method type" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2009",
        :cvv => "100",
        :token => "CREDIT_CARD_TOKEN"
      )

      expect do
        Braintree::PayPalAccount.find("CREDIT_CARD_TOKEN")
      end.to raise_error(Braintree::NotFoundError)
    end
  end

  describe "self.update" do
    it "updates a paypal account's token" do
      with_altpay_merchant do
        config = Braintree::Configuration.instantiate
        customer = Braintree::Customer.create!
        original_token = "paypal-account-#{Time.now.to_i}"
        client_token = Braintree::ClientToken.generate
        authorization_fingerprint = JSON.parse(client_token)["authorizationFingerprint"]
        http = ClientApiHttp.new(
          config,
          :authorization_fingerprint => authorization_fingerprint,
        )

        response = http.create_paypal_account(
          :consent_code => "consent-code",
          :token => original_token,
        )
        response.code.should == "202"

        nonce = JSON.parse(response.body)["paypalAccounts"].first["nonce"]

        original_result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id
        )

        updated_token = "UPDATED_TOKEN-" + rand(36**3).to_s(36)
        updated_result = Braintree::PayPalAccount.update(
          original_token,
          :token => updated_token
        )

        updated_paypal_account = Braintree::PayPalAccount.find(updated_token)
        updated_paypal_account.email.should == original_result.payment_method.email

        expect do
          Braintree::PayPalAccount.find(original_token)
        end.to raise_error(Braintree::NotFoundError, "payment method with token \"#{original_token}\" not found")
      end
    end

    it "handles errors" do
      with_altpay_merchant do
        config = Braintree::Configuration.instantiate
        customer = Braintree::Customer.create!
        first_token = "paypal-account-#{rand(36**3).to_s(36)}"
        second_token = "paypal-account-#{rand(36**3).to_s(36)}"
        client_token = Braintree::ClientToken.generate
        authorization_fingerprint = JSON.parse(client_token)["authorizationFingerprint"]
        http = ClientApiHttp.new(
          config,
          :authorization_fingerprint => authorization_fingerprint,
        )

        first_response = http.create_paypal_account(
          :consent_code => "consent-code",
          :token => first_token,
        )
        first_nonce = JSON.parse(first_response.body)["paypalAccounts"].first["nonce"]
        first_result = Braintree::PaymentMethod.create(
          :payment_method_nonce => first_nonce,
          :customer_id => customer.id
        )

        second_response = http.create_paypal_account(
          :consent_code => "consent-code",
          :token => second_token,
        )
        second_nonce = JSON.parse(second_response.body)["paypalAccounts"].first["nonce"]
        second_result = Braintree::PaymentMethod.create(
          :payment_method_nonce => second_nonce,
          :customer_id => customer.id
        )

        updated_result = Braintree::PayPalAccount.update(
          first_token,
          :token => second_token
        )

        updated_result.should_not be_success
        updated_result.errors.first.code.should == "92906"
      end
    end
  end

  context "delete" do
    it "deletes a PayPal account" do
      with_altpay_merchant do
        config = Braintree::Configuration.instantiate
        customer = Braintree::Customer.create!
        token = "paypal-account-#{Time.now.to_i}"
        client_token = Braintree::ClientToken.generate
        authorization_fingerprint = JSON.parse(client_token)["authorizationFingerprint"]
        http = ClientApiHttp.new(
          config,
          :authorization_fingerprint => authorization_fingerprint,
        )

        response = http.create_paypal_account(
          :consent_code => "consent-code",
          :token => token,
        )
        response.code.should == "202"

        nonce = JSON.parse(response.body)["paypalAccounts"].first["nonce"]

        Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id
        )

        result = Braintree::PayPalAccount.delete(token)

        expect do
          Braintree::PayPalAccount.find(token)
        end.to raise_error(Braintree::NotFoundError, "payment method with token \"#{token}\" not found")
      end
    end
  end
end
