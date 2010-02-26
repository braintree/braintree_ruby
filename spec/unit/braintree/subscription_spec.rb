require File.dirname(__FILE__) + "/../spec_helper"

describe Braintree::Subscription do
  context "price" do
    it "accepts price as either a String or a BigDecimal" do
      Braintree::Subscription.new(:price => "12.34", :transactions => []).price.should == BigDecimal.new("12.34")
      Braintree::Subscription.new(:price => BigDecimal.new("12.34"), :transactions => []).price.should == BigDecimal.new("12.34")
    end

    it "blows up if price is not a string or BigDecimal" do
      expect {
        Braintree::Subscription.new(:price => 12.34, :transactions => [])
      }.to raise_error(/Argument must be a String or BigDecimal/)
    end
  end
end
