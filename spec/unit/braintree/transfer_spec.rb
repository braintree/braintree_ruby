require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Transfer do
  describe "new" do
    it "is protected" do
      expect do
        Braintree::Transfer.new
      end.to raise_error(NoMethodError, /protected method .new/)
    end
  end

  describe "inspect" do
    it "prints attributes of transfer object" do
      transfer = Braintree::Transfer._new(
        :gateway,
        :id => "my_id",
        :amount => "10.00",
        :message => "bank_rejected",
        :disbursement_date => Date.new(2014, 2, 12),
        :follow_up_action => "update",
        :merchant_account_id => "token"
      )

      transfer.inspect.should == '#<Braintree::Transfer id: "my_id", amount: "10.0", message: "bank_rejected", disbursement_date: 2014-02-12, follow_up_action: "update">'
    end
  end
end
