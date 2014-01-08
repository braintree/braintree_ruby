
require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::AuthorizationInfo do
  describe "self.generate" do
    it "returns a fingerprint with the public_key, and created at timestamp" do
      auth_info = Braintree::AuthorizationInfo.generate
      fingerprint = JSON.parse(auth_info)["fingerprint"]
      signature, encoded_data = fingerprint.split("|")

      signature.length.should > 1
      encoded_data.should include("public_key=#{Braintree::Configuration.public_key}")
      encoded_data.should =~ /created_at=\d+/
    end

    it "returns client_api_url and auth_url" do
      auth_info = JSON.parse(Braintree::AuthorizationInfo.generate)

      client_api_url = "http://localhost:#{ENV['GATEWAY_PORT'] || 3000}/merchants/#{Braintree::Configuration.merchant_id}/client_api"
      auth_info["client_api_url"].should == client_api_url
      auth_info["auth_url"].should == "http://auth.venmo.dev"
    end

    it "can optionally take a customer id" do
      auth_info = Braintree::AuthorizationInfo.generate(:customer_id => 1)
      fingerprint = JSON.parse(auth_info)["fingerprint"]
      signature, encoded_data = fingerprint.split("|")

      signature.length.should > 1
      encoded_data.should include("customer_id=1")
    end

    it "can't overwrite public_key, or created_at" do
      auth_info = Braintree::AuthorizationInfo.generate(
        :public_key => "bad_key",
        :created_at => "bad_time"
      )
      fingerprint = JSON.parse(auth_info)["fingerprint"]

      signature, encoded_data = fingerprint.split("|")

      signature.length.should > 1
      encoded_data.should include("public_key=#{Braintree::Configuration.public_key}")
      encoded_data.should =~ /created_at=\d+/
    end

    it "can include credit_card options" do
      auth_info = Braintree::AuthorizationInfo.generate(
        :customer_id => 1,
        :verify_card => true,
        :fail_on_duplicate_payment_method => true,
        :make_default => true
      )
      fingerprint = JSON.parse(auth_info)["fingerprint"]

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
            Braintree::AuthorizationInfo.generate(
              option_name.to_sym => true
            )
          end.to raise_error(ArgumentError, /#{option_name}/)
        end
      end
    end
  end
end
