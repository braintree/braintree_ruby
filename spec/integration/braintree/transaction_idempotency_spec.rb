require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Transaction, "idempotency" do
  describe "sale" do
    it "returns original transaction on duplicate request with same api_request_key" do
      api_request_key = "idempotency-key-#{rand(1000000)}"

      transaction_params = {
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :api_request_key => api_request_key,
        :credit_card => {
          :number => "4111111111111111",
          :expiration_date => "05/2035"
        }
      }

      result1 = Braintree::Transaction.sale(transaction_params)
      expect(result1).to be_success
      transaction1 = result1.transaction
      expect(transaction1.id).not_to be_nil

      result2 = Braintree::Transaction.sale(transaction_params)
      expect(result2).to be_success
      transaction2 = result2.transaction

      expect(transaction1.status).to eq(transaction2.status)
      expect(transaction1.id).to eq(transaction2.id)
    end

    it "fails when different request used with same key" do
      api_request_key = "idempotency-key-#{rand(1000000)}"

      transaction_params1 = {
        :amount => "100.00",
        :api_request_key => api_request_key,
        :credit_card => {
          :number => "4111111111111111",
          :expiration_date => "05/2035"
        }
      }

      result1 = Braintree::Transaction.sale(transaction_params1)
      expect(result1).to be_success

      transaction_params2 = {
        :amount => "200.00",
        :api_request_key => api_request_key,
        :credit_card => {
          :number => "4111111111111111",
          :expiration_date => "05/2035"
        }
      }

      result2 = Braintree::Transaction.sale(transaction_params2)

      expect(result2).not_to be_success
      expect(result2.errors).not_to be_nil
      errors = result2.errors.for(:transaction)
      expect(errors.size).to be > 0
      expect(errors.first.code).to eq(Braintree::ErrorCodes::Transaction::ApiRequestKeyCanBeReusedOnlyWithTheSameRequest)
    end

    it "same sales with different api_request_keys create different transactions" do
      api_request_key1 = "idempotency-key-#{rand(1000000)}"

      transaction_params1 = {
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :api_request_key => api_request_key1,
        :credit_card => {
          :number => "4111111111111111",
          :expiration_date => "05/2035"
        }
      }

      result1 = Braintree::Transaction.sale(transaction_params1)
      expect(result1).to be_success
      transaction1 = result1.transaction
      expect(transaction1.id).not_to be_nil

      api_request_key2 = "idempotency-key-different-#{rand(1000000)}"
      transaction_params2 = {
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :api_request_key => api_request_key2,
        :credit_card => {
          :number => "4111111111111111",
          :expiration_date => "05/2035"
        }
      }

      result2 = Braintree::Transaction.sale(transaction_params2)
      expect(result2).to be_success
      transaction2 = result2.transaction

      expect(transaction1.id).not_to eq(transaction2.id)
    end

    it "fails when api_request_key is too big" do
      transaction_params1 = {
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :api_request_key => "x" * 255,
        :credit_card => {
          :number => "4111111111111111",
          :expiration_date => "05/2035"
        }
      }

      result1 = Braintree::Transaction.sale(transaction_params1)
      expect(result1).to be_success

      transaction_params2 = {
        :amount => "200.00",
        :api_request_key => "x" * 256,
        :credit_card => {
          :number => "4111111111111111",
          :expiration_date => "05/2035"
        }
      }

      result2 = Braintree::Transaction.sale(transaction_params2)

      expect(result2).not_to be_success
      expect(result2.errors).not_to be_nil
      errors = result2.errors.for(:transaction)
      expect(errors.size).to be > 0
      expect(errors.first.code).to eq(Braintree::ErrorCodes::Transaction::ApiRequestKeyTooLong)
    end
  end

  describe "credit" do
    it "returns original on duplicate request with same api_request_key" do
      api_request_key = "credit-idempotency-key-#{rand(1000000)}"

      transaction_params = {
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :api_request_key => api_request_key,
        :credit_card => {
          :number => "4111111111111111",
          :expiration_date => "05/2035"
        }
      }

      credit_result1 = Braintree::Transaction.credit(transaction_params)
      expect(credit_result1).to be_success
      credit_transaction1 = credit_result1.transaction
      expect(credit_transaction1.type).to eq(Braintree::Transaction::Type::Credit)
      expect(credit_transaction1.id).not_to be_nil

      credit_result2 = Braintree::Transaction.credit(transaction_params)
      expect(credit_result2).to be_success
      credit_transaction2 = credit_result2.transaction

      expect(credit_transaction1.id).to eq(credit_transaction2.id)
      expect(credit_transaction1.type).to eq(credit_transaction2.type)
    end
  end

  describe "submit_for_partial_settlement" do
    it "returns original on duplicate request with same api_request_key" do
      api_request_key = "partial-settlement-idempotency-key-#{rand(1000000)}"

      sale_request = {
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => "4111111111111111",
          :expiration_date => "05/2035"
        }
      }

      sale_result = Braintree::Transaction.sale(sale_request)
      expect(sale_result).to be_success
      transaction_id = sale_result.transaction.id

      partial_amount = "50.00"
      partial_settlement_options = {
        :api_request_key => api_request_key
      }

      partial_settlement_result1 = Braintree::Transaction.submit_for_partial_settlement(
        transaction_id,
        partial_amount,
        partial_settlement_options,
      )
      expect(partial_settlement_result1).to be_success
      partial_settlement_transaction1 = partial_settlement_result1.transaction
      expect(partial_settlement_transaction1.amount).to eq(BigDecimal(partial_amount))
      expect(partial_settlement_transaction1.id).not_to be_nil

      partial_settlement_result2 = Braintree::Transaction.submit_for_partial_settlement(
        transaction_id,
        partial_amount,
        partial_settlement_options,
      )
      expect(partial_settlement_result2).to be_success
      partial_settlement_transaction2 = partial_settlement_result2.transaction

      expect(partial_settlement_transaction1.id).to eq(partial_settlement_transaction2.id)
      expect(partial_settlement_transaction1.amount).to eq(partial_settlement_transaction2.amount)
    end
  end

  describe "submit_for_settlement" do
    it "returns original on duplicate request with same api_request_key" do
      api_request_key = "settlement-idempotency-key-#{rand(1000000)}"

      sale_request = {
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => "4111111111111111",
          :expiration_date => "05/2035"
        }
      }

      sale_result = Braintree::Transaction.sale(sale_request)
      expect(sale_result).to be_success
      transaction_id = sale_result.transaction.id
      original_amount = sale_result.transaction.amount

      settlement_options = {
        :api_request_key => api_request_key
      }

      settlement_result1 = Braintree::Transaction.submit_for_settlement(
        transaction_id,
        nil,
        settlement_options,
      )
      expect(settlement_result1).to be_success
      settlement_transaction1 = settlement_result1.transaction
      expect(settlement_transaction1.amount).to eq(original_amount)
      expect(settlement_transaction1.id).not_to be_nil

      settlement_result2 = Braintree::Transaction.submit_for_settlement(
        transaction_id,
        nil,
        settlement_options,
      )
      expect(settlement_result2).to be_success
      settlement_transaction2 = settlement_result2.transaction

      expect(settlement_transaction1.id).to eq(settlement_transaction2.id)
      expect(settlement_transaction1.amount).to eq(settlement_transaction2.amount)
    end
  end

  describe "void" do
    it "returns original void on duplicate request with same api_request_key" do
      api_request_key = "void-idempotency-key-#{rand(1000000)}"

      sale_request = {
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => "4111111111111111",
          :expiration_date => "05/2035"
        }
      }

      sale_result = Braintree::Transaction.sale(sale_request)
      expect(sale_result).to be_success
      transaction_id = sale_result.transaction.id

      void_options = {
        :api_request_key => api_request_key
      }

      void_result1 = Braintree::Transaction.void(transaction_id, void_options)
      expect(void_result1).to be_success
      voided_transaction1 = void_result1.transaction
      expect(voided_transaction1.status).to eq(Braintree::Transaction::Status::Voided)

      void_result2 = Braintree::Transaction.void(transaction_id, void_options)
      expect(void_result2).to be_success
      voided_transaction2 = void_result2.transaction

      expect(voided_transaction1.id).to eq(voided_transaction2.id)
      expect(voided_transaction1.status).to eq(voided_transaction2.status)
      expect(voided_transaction2.status).to eq(Braintree::Transaction::Status::Voided)
    end
  end

  describe "refund" do
    it "returns original refund on duplicate request with same api_request_key" do
      api_request_key = "refund-idempotency-key-#{rand(1000000)}"

      sale_request = {
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => "4111111111111111",
          :expiration_date => "05/2035"
        },
        :options => {
          :submit_for_settlement => true
        }
      }

      sale_result = Braintree::Transaction.sale(sale_request)
      expect(sale_result).to be_success
      transaction_id = sale_result.transaction.id

      settled_result = Braintree::TestTransaction.settle(transaction_id)
      expect(settled_result.transaction.status).to eq(Braintree::Transaction::Status::Settled)

      refund_options = {
        :api_request_key => api_request_key
      }

      refund_result1 = Braintree::Transaction.refund(transaction_id, refund_options)
      expect(refund_result1).to be_success
      refund_transaction1 = refund_result1.transaction
      expect(refund_transaction1.type).to eq(Braintree::Transaction::Type::Credit)
      expect(refund_transaction1.id).not_to be_nil

      refund_result2 = Braintree::Transaction.refund(transaction_id, refund_options)
      expect(refund_result2).to be_success
      refund_transaction2 = refund_result2.transaction

      expect(refund_transaction1.id).to eq(refund_transaction2.id)
      expect(refund_transaction1.type).to eq(refund_transaction2.type)
    end
  end
end
