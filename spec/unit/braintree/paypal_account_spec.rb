require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::PayPalAccount do
  describe "default?" do
    it "is true if the credit card is the default credit card for the customer" do
      Braintree::PayPalAccount._new(:gateway, :default => true).default?.should == true
    end

    it "is false if the credit card is not the default credit card for the customer" do
      Braintree::PayPalAccount._new(:gateway, :default => false).default?.should == false
    end
  end
end
