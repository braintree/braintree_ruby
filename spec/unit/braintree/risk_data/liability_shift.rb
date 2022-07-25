require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::Transaction::LiabilityShift do
  describe "#initialize" do
    it "sets responsible party and conditions" do
      liability_shift = Braintree::Transaction::LiabilityShift.new(
        :responsible_party => "paypal",
        :conditions => ["unauthorized","item_not_received"],
      )

      expect(liability_shift.responsible_party).to eql "paypal"
      expect(liability_shift.conditions.first).to eql "unauthorized"
    end
  end

  describe "inspect" do
    it "prints the attributes" do
      details = Braintree::Transaction::LiabilityShift.new(
        :responsible_party => "paypal",
        :conditions => ["unauthorized","item_not_received"],
      )

      expect(details.inspect).to eql %(#<LiabilityShift responsible_party: "paypal", conditions: ["unauthorized", "item_not_received"]>)
    end
  end
end
