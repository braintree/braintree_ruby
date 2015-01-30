require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::PaymentMethodNonce do
  describe "self.create" do
    it "creates a payment method nonce from a vaulted credit card" do
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

      result = Braintree::PaymentMethodNonce.create(found_credit_card.token)
      result.should be_success
      result.payment_method_nonce.should_not be_nil
      result.payment_method_nonce.nonce.should_not be_nil
    end

    it "correctly raises and exception for a non existent token" do
      expect do
        result = Braintree::PaymentMethodNonce.create("not_a_token")
      end.to raise_error(Braintree::NotFoundError)
    end
  end
end
