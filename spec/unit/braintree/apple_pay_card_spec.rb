require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::ApplePayCard do
  describe "default?" do
    it "is true if the Apple pay card is the default payment method for the customer" do
      Braintree::ApplePayCard._new(:gateway, :default => true).default?.should == true
    end

    it "is false if the Apple pay card is not the default payment methodfor the customer" do
      Braintree::ApplePayCard._new(:gateway, :default => false).default?.should == false
    end
  end
end
