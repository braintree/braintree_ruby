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
end
