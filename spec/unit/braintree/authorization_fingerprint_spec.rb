
require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::AuthorizationFingerprint do
  describe "self.generate" do
    it "returns a fingerprint with the merchant_id, public_key, and created at timestamp" do
      fingerprint = Braintree::AuthorizationFingerprint.generate
      signature, encoded_data = fingerprint.split("|")

      signature.length.should > 1
      encoded_data.should include("merchant_id=#{Braintree::Configuration.merchant_id}")
      encoded_data.should include("public_key=#{Braintree::Configuration.public_key}")
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
  end
end
