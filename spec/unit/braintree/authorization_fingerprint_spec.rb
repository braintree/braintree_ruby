
require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::AuthorizationFingerprint do
  describe "self.generate" do
    it "returns a fingerprint with the merchant_id, public_key, base_url, and created at timestamp" do
      fingerprint = Braintree::AuthorizationFingerprint.generate
      signature, encoded_data = fingerprint.split("|")

      signature.length.should > 1
      encoded_data.should include("merchant_id=#{Braintree::Configuration.merchant_id}")
      encoded_data.should include("public_key=#{Braintree::Configuration.public_key}")

      base_url = "http://localhost:#{ENV['GATEWAY_PORT'] || 3000}/merchants/#{Braintree::Configuration.merchant_id}"
      encoded_data.should include("base_url=#{base_url}")
      encoded_data.should =~ /created_at=\d+/
    end

    it "can optionally take a customer id" do
      fingerprint = Braintree::AuthorizationFingerprint.generate(:customer_id => 1)
      signature, encoded_data = fingerprint.split("|")

      signature.length.should > 1
      encoded_data.should include("customer_id=1")
    end

    it "can't overwrite merchant_id, public_key, or created_at" do
      fingerprint = Braintree::AuthorizationFingerprint.generate(
        :merchant_id => "bad_id",
        :public_key => "bad_key",
        :created_at => "bad_time"
      )

      signature, encoded_data = fingerprint.split("|")

      signature.length.should > 1
      encoded_data.should include("merchant_id=#{Braintree::Configuration.merchant_id}")
      encoded_data.should include("public_key=#{Braintree::Configuration.public_key}")
      encoded_data.should =~ /created_at=\d+/
    end

    it "can include credit_card options" do
      fingerprint = Braintree::AuthorizationFingerprint.generate(
        :customer_id => 1,
        :verify_card => true,
        :fail_on_duplicate_payment_method => true,
        :make_default => true
      )

      signature, encoded_data = fingerprint.split("|")

      signature.length.should > 1
      encoded_data.should include("credit_card[options][make_default]=true")
      encoded_data.should include("credit_card[options][fail_on_duplicate_payment_method]=true")
      encoded_data.should include("credit_card[options][verify_card]=true")
    end

    context "adding credit_card options with no customer ID" do
      %w(verify_card fail_on_duplicate_payment_method make_default).each do |option_name|
        it "raises an ArgumentError if #{option_name} is present" do
          expect do
            Braintree::AuthorizationFingerprint.generate(
              option_name.to_sym => true
            )
          end.to raise_error(ArgumentError, /#{option_name}/)
        end
      end
    end
  end
end
