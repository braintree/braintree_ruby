require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::PaymentMethodNonceDetailsPayerInfo do
  let(:payment_method_nonce_details_payer_info) {
    Braintree::PaymentMethodNonceDetailsPayerInfo.new(
      :billing_agreement_id => "billing-agreement-id",
      :country_code => "US",
      :email => "test@example.com",
      :first_name => "First",
      :last_name => "Last",
      :payer_id => "payer-id",
    )
  }

  describe "#initialize" do
    it "sets attributes" do
      expect(payment_method_nonce_details_payer_info.billing_agreement_id).to eq("billing-agreement-id")
      expect(payment_method_nonce_details_payer_info.country_code).to eq("US")
      expect(payment_method_nonce_details_payer_info.email).to eq("test@example.com")
      expect(payment_method_nonce_details_payer_info.first_name).to eq("First")
      expect(payment_method_nonce_details_payer_info.last_name).to eq("Last")
      expect(payment_method_nonce_details_payer_info.payer_id).to eq("payer-id")
    end
  end

  describe "inspect" do
    it "prints the attributes" do
      expect(payment_method_nonce_details_payer_info.inspect).to eq(%(#<PaymentMethodNonceDetailsPayerInfo billing_agreement_id: \"billing-agreement-id\", country_code: \"US\", email: \"test@example.com\", first_name: \"First\", last_name: \"Last\", payer_id: \"payer-id\">))
    end
  end
end
