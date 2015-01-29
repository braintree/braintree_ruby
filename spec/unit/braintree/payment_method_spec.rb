require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::PaymentMethod do
  describe "find" do
    it "handles an unknown payment method type" do
      unknown_response = {:unknown_payment_method => {:token => 1234, :default => true}}
      http_instance = double(:get => unknown_response)
      Braintree::Http.stub(:new).and_return(http_instance)
      unknown_payment_method = Braintree::PaymentMethod.find("UNKNOWN_PAYMENT_METHOD_TOKEN")

      unknown_payment_method.token.should == 1234
      unknown_payment_method.default?.should be(true)
    end
  end

  describe "timestamps" do
    it "exposes created_at and updated_at" do
      now = Time.now
      paypal_account = Braintree::PayPalAccount._new(:gateway, :updated_at => now, :created_at => now)

      paypal_account.created_at.should == now
      paypal_account.updated_at.should == now
    end
  end
end
