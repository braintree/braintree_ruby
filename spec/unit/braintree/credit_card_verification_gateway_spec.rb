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

      result.inspect.should include("merchant_id")
      result.inspect.should include("public_key")
      result.inspect.should include("private_key")
    end

    it "creates a credit card verification gateway signature" do
      result = Braintree::CreditCardVerificationGateway._create_signature
      result.inspect.should include("credit_card")
      result.inspect.should include("credit_card")
      result.inspect.should include("cardholder_name")
      result.inspect.should include("cvv")
      result.inspect.should include("expiration_date")
      result.inspect.should include("expiration_month")
      result.inspect.should include("expiration_year")
      result.inspect.should include("number")
      result.inspect.should include("billing_address")
      result.inspect.should include("intended_transaction_source")
      result.inspect.should include("options")
      result.inspect.should include("amount")
      result.inspect.should include("merchant_account_id")
      result.inspect.should include("account_type")
      result.inspect.should include("payment_method_nonce")
      result.inspect.should include("three_d_secure_authentication_id")
      result.inspect.should include("three_d_secure_pass_thru")
      result.inspect.should include("eci_flag")
      result.inspect.should include("cavv")
      result.inspect.should include("xid")
      result.inspect.should include("three_d_secure_version")
      result.inspect.should include("authentication_response")
      result.inspect.should include("directory_response")
      result.inspect.should include("cavv_algorithm")
      result.inspect.should include("ds_transaction_id")
    end
  end
end
