require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::CreditCardVerificationGateway do
  describe "Credit Card Verification Gateway" do
    let(:gateway) do
      config = Braintree::Configuration.new(
        :merchant_id => "merchant_id",
        :public_key => "public_key",
        :private_key => "private_key",
      )
      Braintree::Gateway.new(config)
    end

    it "creates a credit card verification gateway" do
      result = Braintree::CreditCardVerificationGateway.new(gateway)

      expect(result.inspect).to include("merchant_id")
      expect(result.inspect).to include("public_key")
      expect(result.inspect).to include("private_key")
    end

    it "creates a credit card verification gateway signature" do
      result = Braintree::CreditCardVerificationGateway._create_signature
      expect(result.inspect).to include("credit_card")
      expect(result.inspect).to include("credit_card")
      expect(result.inspect).to include("cardholder_name")
      expect(result.inspect).to include("cvv")
      expect(result.inspect).to include("expiration_date")
      expect(result.inspect).to include("expiration_month")
      expect(result.inspect).to include("expiration_year")
      expect(result.inspect).to include("number")
      expect(result.inspect).to include("billing_address")
      expect(result.inspect).to include("intended_transaction_source")
      expect(result.inspect).to include("options")
      expect(result.inspect).to include("amount")
      expect(result.inspect).to include("merchant_account_id")
      expect(result.inspect).to include("account_type")
      expect(result.inspect).to include("payment_method_nonce")
      expect(result.inspect).to include("three_d_secure_authentication_id")
      expect(result.inspect).to include("three_d_secure_pass_thru")
      expect(result.inspect).to include("eci_flag")
      expect(result.inspect).to include("cavv")
      expect(result.inspect).to include("xid")
      expect(result.inspect).to include("three_d_secure_version")
      expect(result.inspect).to include("authentication_response")
      expect(result.inspect).to include("directory_response")
      expect(result.inspect).to include("cavv_algorithm")
      expect(result.inspect).to include("ds_transaction_id")
    end
  end
end
