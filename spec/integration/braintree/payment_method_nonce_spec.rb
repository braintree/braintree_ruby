require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::PaymentMethodNonce do
  let(:config) { Braintree::Configuration.instantiate }

  describe "self.create" do
    it "creates a payment method nonce from a vaulted credit card" do
      customer = Braintree::Customer.create.customer
      nonce = nonce_for_new_payment_method(
        :credit_card => {
          :number => "4111111111111111",
          :expiration_month => "11",
          :expiration_year => "2099",
        }
      )

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
        Braintree::PaymentMethodNonce.create("not_a_token")
      end.to raise_error(Braintree::NotFoundError)
    end
  end

  describe "self.find" do
    it "finds and returns the nonce if one was found" do
      result = Braintree::PaymentMethodNonce.find("threedsecurednonce")

      nonce = result.payment_method_nonce

      result.should be_success
      nonce.nonce.should == "threedsecurednonce"
      nonce.type.should == "CreditCard"
      nonce.three_d_secure_info.liability_shifted.should == true
    end

    it "returns null 3ds_info if there isn't any" do
      nonce = nonce_for_new_payment_method(
        :credit_card => {
          :number => "4111111111111111",
          :expiration_month => "11",
          :expiration_year => "2099",
        }
      )

      result = Braintree::PaymentMethodNonce.find(nonce)

      nonce = result.payment_method_nonce

      result.should be_success
      nonce.three_d_secure_info.should be_nil
    end

    it "correctly raises and exception for a non existent token" do
      expect do
        Braintree::PaymentMethodNonce.find("not_a_nonce")
      end.to raise_error(Braintree::NotFoundError)
    end
  end
end
