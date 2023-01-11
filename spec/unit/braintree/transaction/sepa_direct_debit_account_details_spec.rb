require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::Transaction::SepaDirectDebitAccountDetails do
  describe "initialize" do
    let(:params) do
      {
        bank_reference_token: "a-reference-token",
        capture_id: "a-capture-id",
        debug_id: "a-debug-id",
        global_id: "a-global-id",
        last_4: "1234",
        mandate_type: "ONE_OFF",
        merchant_or_partner_customer_id: "12312312343",
        paypal_v2_order_id: "a-paypal-v2-order-id",
        refund_from_transaction_fee_amount: "2.34",
        refund_from_transaction_fee_currency_iso_code: "EUR",
        refund_id: "a-refund-id",
        settlement_type: "INSTANT",
        token: "a-token",
        transaction_fee_amount: "12.34",
        transaction_fee_currency_iso_code: "EUR",
      }
    end

    subject do
      described_class.new(params)
    end

    it "sets all fields" do
      is_expected.to have_attributes(**params)
    end
  end
end
