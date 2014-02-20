require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::DisbursementException do
  describe "new" do
    it "is protected" do
      expect do
        Braintree::DisbursementException.new
      end.to raise_error(NoMethodError, /protected method .new/)
    end
  end

  describe "inspect" do
    it "prints attributes of disbursement_exception object" do
      disbursement_exception = Braintree::DisbursementException._new(
        :gateway,
        :id => "my_id",
        :amount => "10.00",
        :message => "bank_rejected",
        :disbursement_date => Date.new(2014, 2, 12),
        :follow_up_action => "update",
        :merchant_account_id => "token"
      )

      disbursement_exception.inspect.should == '#<Braintree::DisbursementException id: "my_id", amount: "10.0", message: "bank_rejected", disbursement_date: 2014-02-12, follow_up_action: "update">'
    end
  end
end
