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
      payment_method_nonce_details.bin.should == "bin"
      payment_method_nonce_details.card_type.should == "American Express"
      payment_method_nonce_details.expiration_month.should == "12"
      payment_method_nonce_details.expiration_year.should == "2025"
      payment_method_nonce_details.is_network_tokenized.should == true
      payment_method_nonce_details.last_two.should == "11"
      payment_method_nonce_details.payer_info.billing_agreement_id.should == "1234"
      payment_method_nonce_details.payer_info.country_code.should == "US"
      payment_method_nonce_details.sepa_direct_debit_account_nonce_details.bank_reference_token.should == "a-bank-reference-token"
      payment_method_nonce_details.sepa_direct_debit_account_nonce_details.last_4.should == "abcd"
      payment_method_nonce_details.sepa_direct_debit_account_nonce_details.mandate_type.should == "ONE_OFF"
      payment_method_nonce_details.sepa_direct_debit_account_nonce_details.merchant_or_partner_customer_id.should == "a-mp-customer-id"
    end
  end

  describe "inspect" do
    it "prints the attributes" do
      payment_method_nonce_details.inspect.should == %(#<PaymentMethodNonceDetails bin: "bin", card_type: "American Express", expiration_month: "12", expiration_year: "2025", is_network_tokenized: true, last_two: "11", payer_info: #<PaymentMethodNonceDetailsPayerInfo billing_agreement_id: "1234", country_code: "US", email: nil, first_name: nil, last_name: nil, payer_id: nil>, sepa_direct_debit_account_nonce_details: #<SepaDirectDebitAccountNonceDetailsbank_reference_token: "a-bank-reference-token", last_4: "abcd", mandate_type: "ONE_OFF", merchant_or_partner_customer_id: "a-mp-customer-id">>)
    end
  end

  describe "is_network_tokenized" do
    it "is aliased to is_network_tokenized?" do
      payment_method_nonce_details.is_network_tokenized?.should == true
    end
  end
end
