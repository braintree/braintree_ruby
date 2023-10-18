require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::LocalPaymentExpired do
  describe "self.new" do
    it "is protected" do
      expect do
        Braintree::LocalPaymentExpired.new
      end.to raise_error(NoMethodError, /protected method .new/)
    end
  end

  describe "self._new" do
    it "initializes the object with the appropriate attributes set" do
      params = {
        payment_id: "a-payment-id",
        payment_context_id: "a-payment-context-id",
      }
      local_payment_expired = Braintree::LocalPaymentExpired._new(params)

      expect(local_payment_expired.payment_id).to eq("a-payment-id")
      expect(local_payment_expired.payment_context_id).to eq("a-payment-context-id")
    end
  end
end
