require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::Transaction::Installment do
  describe "inspect" do
    it "assigns all fields" do
      adjustment_attributes = {
        :amount => "0.98",
        :kind => "REFUND",
        :projected_disbursement_date => "2020-01-03 01:02:03Z",
        :actual_disbursement_date => "2020-01-04 01:02:03Z",
      }
      installment_attributes = {
        :id => "abc123",
        :amount => "1.23",
        :projected_disbursement_date => "2020-01-01 01:02:03Z",
        :actual_disbursement_date => "2020-01-02 01:02:03Z",
        :adjustments => [adjustment_attributes],
      }

      installment = Braintree::Transaction::Installment.new(installment_attributes)

      expect(installment.inspect).to eq('#<id: "abc123", amount: 0.123e1, projected_disbursement_date: "2020-01-01 01:02:03Z", actual_disbursement_date: "2020-01-02 01:02:03Z", adjustments: [#<amount: 0.98e0, kind: "REFUND", projected_disbursement_date: "2020-01-03 01:02:03Z", actual_disbursement_date: "2020-01-04 01:02:03Z">]>')
    end
  end
end
