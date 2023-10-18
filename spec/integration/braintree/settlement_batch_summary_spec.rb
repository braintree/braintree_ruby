# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::SettlementBatchSummary do
  describe "self.generate" do
    it "returns an empty collection if there is not data" do
      result = Braintree::SettlementBatchSummary.generate("1979-01-01")
      expect(result).to be_success
      expect(result.settlement_batch_summary.records.size).to be_zero
    end

    it "returns an error response if the date cannot be parsed" do
      result = Braintree::SettlementBatchSummary.generate("NOT A DATE :(")
      expect(result).not_to be_success
      expect(result.errors.for(:settlement_batch_summary).on(:settlement_date).map { |e| e.code }).to include(Braintree::ErrorCodes::SettlementBatchSummary::SettlementDateIsInvalid)
    end

    it "returns transactions settled on a given day" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::AmExes.first,
          :expiration_date => "05/2012",
          :cardholder_name => "Sergio Ramos"
        },
        :options => {:submit_for_settlement => true},
      )
      result = SpecHelper.settle_transaction transaction.id
      settlement_date = result[:transaction][:settlement_batch_id].split("_").first
      result = Braintree::SettlementBatchSummary.generate(settlement_date)

      expect(result).to be_success
      amex_records = result.settlement_batch_summary.records.select { |row| row[:card_type] == Braintree::CreditCard::CardType::AmEx }
      expect(amex_records.first[:count].to_i).to be >= 1
      expect(amex_records.first[:amount_settled].to_i).to be >= Braintree::Test::TransactionAmounts::Authorize.to_i
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
        :options => {:submit_for_settlement => true},
      )
      result = SpecHelper.settle_transaction transaction.id
      settlement_date = result[:transaction][:settlement_batch_id].split("_").first
      result = Braintree::SettlementBatchSummary.generate(settlement_date, "store_me")

      expect(result).to be_success
      amex_records = result.settlement_batch_summary.records.select { |row| row[:store_me] == "1" }
      expect(amex_records).not_to be_empty
      expect(amex_records.first[:count].to_i).to be >= 1
      expect(amex_records.first[:amount_settled].to_i).to be >= Braintree::Test::TransactionAmounts::Authorize.to_i
    end
  end
end
