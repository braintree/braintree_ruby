# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::SettlementBatchSummary do
  describe "self.generate" do
    it "returns an empty collection if there is not data" do
      settlement_batch_summary = Braintree::SettlementBatchSummary.generate("1979-01-01")
      settlement_batch_summary.records.size.should be_zero
    end

    it "returns transactions settled on a given day" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::AmExes.first,
          :expiration_date => "05/2012",
          :cardholder_name => "Sergio Ramos"
        },
        :options => { :submit_for_settlement => true }
      )
      SpecHelper.settle_transaction transaction.id

      settlement_batch_summary = Braintree::SettlementBatchSummary.generate(now_in_eastern)
      amex_records = settlement_batch_summary.records.select {|row| row[:card_type] == Braintree::CreditCard::CardType::AmEx }
      amex_records.first[:count].to_i.should >= 1
      amex_records.first[:amount_settled].to_i.should >= Braintree::Test::TransactionAmounts::Authorize.to_i
    end

    it "can be grouped by a custom field" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::AmExes.first,
          :expiration_date => "05/2012",
          :cardholder_name => "Sergio Ramos"
        },
        :custom_fields => {
          :store_me => "1"
        },
        :options => { :submit_for_settlement => true }
      )
      SpecHelper.settle_transaction transaction.id

      settlement_batch_summary = Braintree::SettlementBatchSummary.generate(
        now_in_eastern,
        :group_by_custom_field => 'store_me'
      )

      amex_records = settlement_batch_summary.records.select {|row| row[:store_me] == "1" }
      amex_records.should_not be_empty
      amex_records.first[:count].to_i.should >= 1
      amex_records.first[:amount_settled].to_i.should >= Braintree::Test::TransactionAmounts::Authorize.to_i
    end
  end
end
