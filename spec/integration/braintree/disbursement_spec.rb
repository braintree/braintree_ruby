require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::Disbursement do
  describe "merchant_account" do
    it "finds the merchant account with the id passed in the attributes" do
      attributes = {
        :merchant_account_id => "sandbox_sub_merchant_account",
        :id => "123456",
        :message => "invalid_account_number",
        :amount => "100.00",
        :disbursement_date => Date.new(2013, 4, 10),
        :follow_up_action => "update"
      }

      disbursement = Braintree::Disbursement._new(Braintree::Configuration.gateway, attributes)
      disbursement.merchant_account.id.should == "sandbox_sub_merchant_account"
    end
  end

  describe "transactions" do
    it "finds the transactions associated with the disbursement" do
      attributes = {
        :merchant_account_id => "sandbox_sub_merchant_account",
        :id => "123456",
        :message => "invalid_account_number",
        :amount => "100.00",
        :disbursement_date => Date.new(2013, 4, 10),
        :follow_up_action => "update"
      }

      disbursement = Braintree::Disbursement._new(Braintree::Configuration.gateway, attributes)
      disbursement.transactions.maximum_size.should == 1
      transaction = disbursement.transactions.first
      transaction.id.should == "sub_merchant_transaction"
    end
  end
end
