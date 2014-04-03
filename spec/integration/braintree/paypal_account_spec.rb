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
  end
end
