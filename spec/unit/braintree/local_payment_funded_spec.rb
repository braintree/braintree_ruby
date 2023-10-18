require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::LocalPaymentFunded do
  describe "self.new" do
    it "is protected" do
      expect do
        Braintree::LocalPaymentFunded.new
      end.to raise_error(NoMethodError, /protected method .new/)
    end
  end

  describe "self._new" do
    it "initializes the object with the appropriate attributes set" do
      params = {
        payment_id: "a-payment-id",
        payment_context_id: "a-payment-context-id",
        transaction: {
          id: "a-transaction-id",
          amount: "31.00",
          order_id: "an-order-id",
          status: Braintree::Transaction::Status::Settled,
        },
      }
      local_payment_funded = Braintree::LocalPaymentFunded._new(params)

      expect(local_payment_funded.payment_id).to eq("a-payment-id")
      expect(local_payment_funded.payment_context_id).to eq("a-payment-context-id")
      expect(local_payment_funded.transaction.id).to eq("a-transaction-id")
      expect(local_payment_funded.transaction.amount).to eq(31.0)
      expect(local_payment_funded.transaction.order_id).to eq("an-order-id")
      expect(local_payment_funded.transaction.status).to eq(Braintree::Transaction::Status::Settled)
    end
  end
end
