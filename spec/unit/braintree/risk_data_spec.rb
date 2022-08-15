require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::RiskData do
  describe "#initialize" do
    it "sets id, decision, device_data_captured, decision_reasons and transaction_risk_score" do
      risk_data = Braintree::RiskData.new(:id => "123", :decision => "YOU WON $1000 DOLLARS", :device_data_captured => true, :fraud_service_provider => "fraud_protection", :decision_reasons => ["reason"], :transaction_risk_score => "12")
      expect(risk_data.id).to eql "123"
      expect(risk_data.decision).to eql "YOU WON $1000 DOLLARS"
      expect(risk_data.device_data_captured).to be_truthy
      expect(risk_data.fraud_service_provider).to eql "fraud_protection"
      expect(risk_data.decision_reasons).to eql ["reason"]
      expect(risk_data.transaction_risk_score).to eql "12"
      expect(risk_data.liability_shift).to be_nil
    end

    it "sets liability shift info" do
      risk_data = Braintree::RiskData.new(
        :id => "123",
        :decision => "YOU WON $1000 DOLLARS",
        :device_data_captured => true,
        :fraud_service_provider => "fraud_protection",
        :decision_reasons => ["reason"],
        :transaction_risk_score => "12",
        :liability_shift => {
          :responsible_party => "paypal",
          :conditions => ["unauthorized"]},
      )
      expect(risk_data.liability_shift.responsible_party).to eql "paypal"
      expect(risk_data.liability_shift.conditions).to eql ["unauthorized"]
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
      expect(details.inspect).to eql %(#<RiskData id: "123", decision: "YOU WON $1000 DOLLARS", decision_reasons: ["reason"], device_data_captured: true, fraud_service_provider: "fraud_protection", liability_shift: nil, transaction_risk_score: "12">)
    end

    it "prints liability shift attributes, too" do
      details = Braintree::RiskData.new(
        :liability_shift => {
          :responsible_party => "paypal",
          :conditions => ["unauthorized"]},
      )
      expect(details.inspect).to eql %(#<RiskData id: nil, decision: nil, decision_reasons: nil, device_data_captured: nil, fraud_service_provider: nil, liability_shift: #<LiabilityShift responsible_party: "paypal", conditions: ["unauthorized"]>, transaction_risk_score: nil>)
    end
  end
end
