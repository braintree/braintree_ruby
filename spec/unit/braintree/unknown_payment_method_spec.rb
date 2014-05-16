require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::PayPalAccount do
  describe "token" do
    it "has a token identifier" do
      params = {:unknown_payment_method => {:token => 1234, :default => true}}
      Braintree::UnknownPaymentMethod.new(params).token.should == 1234
    end
  end

  describe "default?" do
    it "is true if the paypal account is the default payment method for the customer" do
      params = {:unknown_payment_method => {:token => 1234, :default => true}}
      Braintree::UnknownPaymentMethod.new(params).should be_default
    end

    it "is false if the paypal account is not the default payment methodfor the customer" do
      params = {:unknown_payment_method => {:token => 1234, :default => false}}
      Braintree::UnknownPaymentMethod.new(params).should_not be_default
    end
  end
end
