require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::Transaction do
  describe "self.transfer type" do
    it "should create a transaction with valid transfer types and merchant account id" do
      transaction_params = {
        :type => "sale",
        :amount => "100.00",
        :merchant_account_id => "aft_first_data_wallet_transfer",
        :credit_card => {
          :number => "4111111111111111",
          :expiration_date => "06/2026",
          :cvv => "123"
        },
        :transfer => {
          :type => "wallet_transfer",
        },
      }

      result = Braintree::Transaction.sale(transaction_params)
      expect(result.success?).to eq(true)
      expect(result.transaction.account_funding_transaction).to eq(true)
      expect(result.transaction.status).to eq(Braintree::Transaction::Status::Authorized)
    end

    it "should fail on transaction with non brazil merchant" do
      transaction_params = {
        :type => "sale",
        :amount => "100.00",
        :merchant_account_id => "aft_first_data_wallet_transfer",
        :credit_card => {
          :number => "4111111111111111",
          :expiration_date => "06/2026",
          :cvv => "123"
        },
        :transfer => {
          :type => "invalid_transfer",
        },
      }

      result =  Braintree::Transaction.sale(transaction_params)
      expect(result.success?).to eq(false)
    end
  end
end
