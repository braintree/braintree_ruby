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
        :id => "123456",
        :merchant_account => {
          :id => "sandbox_sub_merchant_account",
          :master_merchant_account => {
            :id => "sandbox_master_merchant_account",
            :status => "active"
          },
          :status => "active"
        },
        :transaction_ids => ["sub_merchant_transaction"],
        :amount => "100.00",
        :disbursement_date => Date.new(2013, 4, 10),
        :exception_message => "invalid_account_number",
        :follow_up_action => "update",
        :retry => false,
        :success => false
      )

      disbursement.inspect.should == '#<Braintree::Disbursement id: "123456", amount: "100.0", exception_message: "invalid_account_number", disbursement_date: 2013-04-10, follow_up_action: "update", merchant_account: #<Braintree::MerchantAccount: id: "sandbox_sub_merchant_account", status: "active", master_merchant_account: #<Braintree::MerchantAccount: id: "sandbox_master_merchant_account", status: "active", master_merchant_account: nil>>, transaction_ids: ["sub_merchant_transaction"], retry: false, success: false>'
    end
  end
end
