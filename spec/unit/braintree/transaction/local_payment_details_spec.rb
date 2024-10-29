require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::Transaction::LocalPaymentDetails do
  describe "initialize" do
    let(:params) do
      {
        blik_aliases: [
          {
            key: "a-key",
            label: "a-label"
          }
        ],
        capture_id: "a-capture-id",
        custom_field: "custom-field",
        debug_id: "debug-id",
        description: "description",
        funding_source: "ideal",
        implicitly_vaulted_payment_method_global_id: "global-id",
        implicitly_vaulted_payment_method_token: "payment-method-token",
        payer_id: "payer-id",
        payment_id: "payment-id",
        refund_from_transaction_fee_amount: "2.34",
        refund_from_transaction_fee_currency_iso_code: "EUR",
        refund_id: "a-refund-id",
        transaction_fee_amount: "12.34",
        transaction_fee_currency_iso_code: "EUR",
      }
    end

    subject { described_class.new(params) }

    it "sets all fields" do
      is_expected.to have_attributes(**params)
    end
  end
end
