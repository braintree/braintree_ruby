require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::Transfer do
  describe "merchant_account" do
    it "finds the merchant account with the id passed in the attributes" do
      attributes = {
        :merchant_account_id => "sandbox_sub_merchant_account",
        :id => "123456",
        :message => "invalid_account_number",
        :amount => "100.00",
        :disbursement_date => "2014-02-10",
        :follow_up_action => "update"
      }

      transfer = Braintree::Transfer._new(Braintree::Configuration.gateway, attributes)
      transfer.merchant_account.id.should == "sandbox_sub_merchant_account"
    end
  end

  describe "transactions" do
    it "finds the merchant account with the id passed in the attributes" do
      attributes = {
        :merchant_account_id => "sandbox_sub_merchant_account",
        :id => "123456",
        :message => "invalid_account_number",
        :amount => "100.00",
        :disbursement_date => Date.new(2013, 4, 10),
        :follow_up_action => "update"
      }

      transfer = Braintree::Transfer._new(Braintree::Configuration.gateway, attributes)
      transfer.transactions.maximum_size.should == 1
      transaction = transfer.transactions.first
      transaction.id.should == "sub_merchant_transaction"
    end
  end
end
