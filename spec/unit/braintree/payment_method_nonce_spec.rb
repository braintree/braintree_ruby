require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::PaymentMethodNonce do
  let(:payment_method_nonce) {
    Braintree::PaymentMethodNonce._new(
      :gateway,
      :nonce => "some-nonce",
      :type => "CreditCard",
      :default => true,
      :details => {
        :bin => "some-bin"
      },
      :three_d_secure_info => {
        :liability_shift_possible => false,
        :liability_shifted => false
      },
      :bin_data => {
        :country_of_issuance => "USA"
      },
    )
  }

  describe "#initialize" do
    it "sets attributes" do
      expect(payment_method_nonce.nonce).to eq("some-nonce")
      expect(payment_method_nonce.type).to eq("CreditCard")
      expect(payment_method_nonce.default).to be true
      expect(payment_method_nonce.details.bin).to eq("some-bin")
      expect(payment_method_nonce.three_d_secure_info.liability_shift_possible).to be false
      expect(payment_method_nonce.three_d_secure_info.liability_shifted).to be false
      expect(payment_method_nonce.bin_data.country_of_issuance).to eq("USA")
    end
  end

  describe "default" do
    it "is aliased to default?" do
      expect(payment_method_nonce.default?).to be true
    end
  end
end
