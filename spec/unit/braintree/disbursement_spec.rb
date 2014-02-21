require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Disbursement do
  describe "new" do
    it "is protected" do
      expect do
        Braintree::Disbursement.new
      end.to raise_error(NoMethodError, /protected method .new/)
    end
  end

  describe "inspect" do
    it "prints attributes of disbursement object" do
      disbursement = Braintree::Disbursement._new(
        :gateway,
        :id => "my_id",
        :amount => "10.00",
        :message => "bank_rejected",
        :disbursement_date => Date.new(2014, 2, 12),
        :follow_up_action => "update",
        :merchant_account_id => "token"
      )

      disbursement.inspect.should == '#<Braintree::Disbursement id: "my_id", amount: "10.0", message: "bank_rejected", disbursement_date: 2014-02-12, follow_up_action: "update">'
    end
  end
end
