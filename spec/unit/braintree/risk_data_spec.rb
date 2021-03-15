require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::RiskData do
  describe "#initialize" do
    it "sets id, decision, device_data_captured, decision_reasons and transaction_risk_score" do
      risk_data = Braintree::RiskData.new(:id => "123", :decision => "YOU WON $1000 DOLLARS", :device_data_captured => true, :fraud_service_provider => "fraud_protection", :decision_reasons => ["reason"], :transaction_risk_score => "12")
      risk_data.id.should == "123"
      risk_data.decision.should == "YOU WON $1000 DOLLARS"
      risk_data.device_data_captured.should be_truthy
      risk_data.fraud_service_provider.should == "fraud_protection"
      risk_data.decision_reasons.should == ["reason"]
      risk_data.transaction_risk_score.should == "12"
    end
  end

  describe "inspect" do
    it "prints the attributes" do
      details = Braintree::RiskData.new(
        :id => "123",
        :decision => "YOU WON $1000 DOLLARS",
        :decision_reasons => ["reason"],
        :device_data_captured => true,
        :fraud_service_provider => "fraud_protection",
        :transaction_risk_score => "12",
      )
      details.inspect.should == %(#<RiskData id: "123", decision: "YOU WON $1000 DOLLARS", decision_reasons: ["reason"], device_data_captured: true, fraud_service_provider: "fraud_protection", transaction_risk_score: "12">)
    end
  end
end
