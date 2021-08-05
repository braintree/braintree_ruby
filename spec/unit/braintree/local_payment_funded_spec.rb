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

      local_payment_funded.payment_id.should eq("a-payment-id")
      local_payment_funded.payment_context_id.should eq("a-payment-context-id")
      local_payment_funded.transaction.id.should eq("a-transaction-id")
      local_payment_funded.transaction.amount.should eq(31.0)
      local_payment_funded.transaction.order_id.should eq("an-order-id")
      local_payment_funded.transaction.status.should eq(Braintree::Transaction::Status::Settled)
    end
  end
end
