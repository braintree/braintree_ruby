require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::PayPalAccount do
  describe "self.update" do
    it "raises an exception if attributes contain an invalid key" do
      expect do
        Braintree::PayPalAccount.update("some_token", :invalid_key => 'val')
      end.to raise_error(ArgumentError, "invalid keys: invalid_key")
    end
  end

  describe "default?" do
    it "is true if the paypal account is the default payment method for the customer" do
      Braintree::PayPalAccount._new(:gateway, :default => true).default?.should == true
    end

    it "is false if the paypal account is not the default payment methodfor the customer" do
      Braintree::PayPalAccount._new(:gateway, :default => false).default?.should == false
    end
  end
end
