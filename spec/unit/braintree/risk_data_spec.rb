require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::RiskData do
  describe "#initialize" do
    it "sets id, decision and device_data_captured" do
      risk_data = Braintree::RiskData.new(:id => "123", :decision => "YOU WON $1000 DOLLARS", :device_data_captured => true)
      risk_data.id.should == "123"
      risk_data.decision.should == "YOU WON $1000 DOLLARS"
      risk_data.device_data_captured.should be_truthy
    end
  end

  describe "inspect" do
    it "prints the attributes" do
      details = Braintree::RiskData.new(
        :id => "123",
        :decision => "YOU WON $1000 DOLLARS",
        :device_data_captured => true
      )
      details.inspect.should == %(#<RiskData id: "123", decision: "YOU WON $1000 DOLLARS", device_data_captured: true>)
    end
  end
end
