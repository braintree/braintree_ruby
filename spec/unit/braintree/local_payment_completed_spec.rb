require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::LocalPaymentCompleted do
  describe "self.new" do
    it "is protected" do
      expect do
        Braintree::LocalPaymentCompleted.new
      end.to raise_error(NoMethodError, /protected method .new/)
    end
  end

  describe "self._new" do
    it "initializes the object with the appropriate attributes set" do
      params = {
        payment_id: "a-payment-id",
        payer_id: "a-payer-id",
      }
      local_payment_completed = Braintree::LocalPaymentCompleted._new(params)

      local_payment_completed.payment_id.should eq("a-payment-id")
      local_payment_completed.payer_id.should eq("a-payer-id")
    end
  end
end
