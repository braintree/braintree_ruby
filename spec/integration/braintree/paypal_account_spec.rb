require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::PayPalAccount do
  describe "self.create" do
    it "adds paypal account to an existing customer" do
      with_altpay_merchant do
        customer = Braintree::Customer.create!
        payment_method_token = "paypal-account-#{Time.now.to_i}"
        result = Braintree::PayPalAccount.create(
          :customer_id => customer.id,
          :token => payment_method_token,
          :consent_code => Braintree::Test::PayPalAccount::SuccessfulConsentCode,
          :email => "customer@example.com",
        )
        result.success?.should == true
        paypal_account = result.paypal_account
        paypal_account.token.should == payment_method_token
        paypal_account.consent_code.should == Braintree::Test::PayPalAccount::SuccessfulConsentCode
        paypal_account.email.should == "customer@example.com"
      end
    end

    context "validation errors" do
      it "returns an error code when no consent code is given" do
        with_altpay_merchant do
          customer = Braintree::Customer.create!
          payment_method_token = "paypal-account-#{Time.now.to_i}"
          result = Braintree::PayPalAccount.create(
            :customer_id => customer.id,
            :token => payment_method_token,
            :email => "customer@example.com",
          )

          result.should_not be_success
          result.errors.for(:paypal_account).map(&:code).should include(Braintree::ErrorCodes::PayPalAccount::ConsentCodeIsRequired)
        end
      end
    end
  end

  describe "self.find" do
    it "returns a PayPalAccount" do
      with_altpay_merchant do
        customer = Braintree::Customer.create!
        payment_method_token = "paypal-account-#{Time.now.to_i}"
        result = Braintree::PayPalAccount.create(
          :customer_id => customer.id,
          :token => payment_method_token,
          :consent_code => Braintree::Test::PayPalAccount::SuccessfulConsentCode,
          :email => "customer@example.com",
        )

        result.should be_success

        paypal_account = Braintree::PayPalAccount.find(payment_method_token)
        paypal_account.should be_a(Braintree::PayPalAccount)
        paypal_account.token.should == payment_method_token
        paypal_account.email.should == "customer@example.com"
      end
    end

    it "raises if the payment method token is not found" do
      with_altpay_merchant do
        expect do
          Braintree::PayPalAccount.find("nonexistant-paypal-account")
        end.to raise_error(Braintree::NotFoundError)
      end
    end
  end
end
