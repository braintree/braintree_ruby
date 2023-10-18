require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::PaymentMethodNonceDetails do
  let(:payment_method_nonce_details) {
    Braintree::PaymentMethodNonceDetails.new(
      :bank_reference_token => "a-bank-reference-token",
      :bin => "bin",
      :card_type => "American Express",
      :expiration_month => "12",
      :expiration_year => "2025",
      :is_network_tokenized => true,
      :last_4 => "abcd",
      :last_two => "11",
      :mandate_type => "ONE_OFF",
      :merchant_or_partner_customer_id => "a-mp-customer-id",
      :payer_info => {
        :billing_agreement_id => "1234",
        :country_code => "US",
      },
    )
  }

  describe "#initialize" do
    it "sets attributes" do
      expect(payment_method_nonce_details.bin).to eq("bin")
      expect(payment_method_nonce_details.card_type).to eq("American Express")
      expect(payment_method_nonce_details.expiration_month).to eq("12")
      expect(payment_method_nonce_details.expiration_year).to eq("2025")
      expect(payment_method_nonce_details.is_network_tokenized).to eq(true)
      expect(payment_method_nonce_details.last_two).to eq("11")
      expect(payment_method_nonce_details.payer_info.billing_agreement_id).to eq("1234")
      expect(payment_method_nonce_details.payer_info.country_code).to eq("US")
      expect(payment_method_nonce_details.sepa_direct_debit_account_nonce_details.bank_reference_token).to eq("a-bank-reference-token")
      expect(payment_method_nonce_details.sepa_direct_debit_account_nonce_details.last_4).to eq("abcd")
      expect(payment_method_nonce_details.sepa_direct_debit_account_nonce_details.mandate_type).to eq("ONE_OFF")
      expect(payment_method_nonce_details.sepa_direct_debit_account_nonce_details.merchant_or_partner_customer_id).to eq("a-mp-customer-id")
    end
  end

  describe "inspect" do
    it "prints the attributes" do
      expect(payment_method_nonce_details.inspect).to eq(%(#<PaymentMethodNonceDetails bin: "bin", card_type: "American Express", expiration_month: "12", expiration_year: "2025", is_network_tokenized: true, last_two: "11", payer_info: #<PaymentMethodNonceDetailsPayerInfo billing_agreement_id: "1234", country_code: "US", email: nil, first_name: nil, last_name: nil, payer_id: nil>, sepa_direct_debit_account_nonce_details: #<SepaDirectDebitAccountNonceDetailsbank_reference_token: "a-bank-reference-token", last_4: "abcd", mandate_type: "ONE_OFF", merchant_or_partner_customer_id: "a-mp-customer-id">>))
    end
  end

  describe "is_network_tokenized" do
    it "is aliased to is_network_tokenized?" do
      expect(payment_method_nonce_details.is_network_tokenized?).to eq(true)
    end
  end
end
