require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::RiskData do
  describe "#initialize" do
    it "sets id and decision" do
      risk_data = Braintree::RiskData.new(:id => "123", :decision => "YOU WON $1000 DOLLARS")
      risk_data.id.should == "123"
      risk_data.decision.should == "YOU WON $1000 DOLLARS"
    end
  end

  describe "inspect" do
    it "prints the attributes" do
      details = Braintree::RiskData.new(
        :id => "123",
        :decision => "YOU WON $1000 DOLLARS"
      )
      details.inspect.should == %(#<RiskData id: "123", decision: "YOU WON $1000 DOLLARS">)
    end
  end
end
