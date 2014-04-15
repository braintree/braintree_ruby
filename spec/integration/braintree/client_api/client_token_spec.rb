require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/spec_helper")

describe Braintree::ClientToken do

  describe "self.generate" do
    it "generates a fingerprint that the gateway accepts" do
      config = Braintree::Configuration.instantiate
      client_token = Braintree::ClientToken.generate
      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => JSON.parse(client_token)["authorizationFingerprint"],
        :shared_customer_identifier => "fake_identifier",
        :shared_customer_identifier_type => "testing"
      )

      response = http.get_cards

      response.code.should == "200"
    end

    it "raises ArgumentError on invalid parameters (422)" do
      expect do
        Braintree::ClientToken.generate(:options => {:make_default => true})
      end.to raise_error(ArgumentError)
    end

    it "can pass verify_card" do
      config = Braintree::Configuration.instantiate
      result = Braintree::Customer.create
      client_token = Braintree::ClientToken.generate(
        :customer_id => result.customer.id,
        :options => {
          :verify_card => true
        }
      )

      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => JSON.parse(client_token)["authorizationFingerprint"],
        :shared_customer_identifier => "fake_identifier",
        :shared_customer_identifier_type => "testing"
      )

      response = http.add_card(
        :credit_card => {
          :number => "4000111111111115",
          :expiration_month => "11",
          :expiration_year => "2099"
        }
      )

      response.code.should == "422"
    end

    it "can pass make_default" do
      config = Braintree::Configuration.instantiate
      result = Braintree::Customer.create
      customer_id = result.customer.id
      client_token = Braintree::ClientToken.generate(
        :customer_id => customer_id,
        :options => {
          :make_default => true
        }
      )

      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => JSON.parse(client_token)["authorizationFingerprint"],
        :shared_customer_identifier => "fake_identifier",
        :shared_customer_identifier_type => "testing"
      )

      response = http.add_card(
        :credit_card => {
          :number => "4111111111111111",
          :expiration_month => "11",
          :expiration_year => "2099"
        }
      )

      response.code.should == "201"

      response = http.add_card(
        :credit_card => {
          :number => "4005519200000004",
          :expiration_month => "11",
          :expiration_year => "2099"
        }
      )

      response.code.should == "201"

      customer = Braintree::Customer.find(customer_id)
      customer.credit_cards.select { |c| c.bin == "400551" }[0].should be_default
    end

    it "can pass fail_on_duplicate_payment_method" do
      config = Braintree::Configuration.instantiate
      result = Braintree::Customer.create
      customer_id = result.customer.id
      client_token = Braintree::ClientToken.generate(
        :customer_id => customer_id
      )

      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => JSON.parse(client_token)["authorizationFingerprint"],
        :shared_customer_identifier => "fake_identifier",
        :shared_customer_identifier_type => "testing"
      )

      response = http.add_card(
        :credit_card => {
          :number => "4111111111111111",
          :expiration_month => "11",
          :expiration_year => "2099"
        }
      )

      response.code.should == "201"

      client_token = Braintree::ClientToken.generate(
        :customer_id => customer_id,
        :options => {
          :fail_on_duplicate_payment_method => true
        }
      )

      http.fingerprint = JSON.parse(client_token)["authorizationFingerprint"]

      response = http.add_card(
        :credit_card => {
          :number => "4111111111111111",
          :expiration_month => "11",
          :expiration_year => "2099"
        }
      )

      response.code.should == "422"
    end

    context "paypal" do
      it "includes the paypal options for a paypal merchant" do
        with_altpay_merchant do
          client_token = Braintree::ClientToken.generate

          parsed_client_token = JSON.parse(client_token)
          parsed_client_token["displayName"].should == "merchant who has paypal and sepa enabled"
          parsed_client_token["paypalPrivacyUrl"].should == "http://www.example.com/privacy_policy"
          parsed_client_token["paypalUserAgreementUrl"].should == "http://www.example.com/user_agreement"
          parsed_client_token["paypalBaseUrl"].should == "127.0.0.1:9292"
        end
      end

      it "does not include the paypal options for a non-paypal merchant" do
        config = Braintree::Configuration.instantiate
        client_token = Braintree::ClientToken.generate

        parsed_client_token = JSON.parse(client_token)
        parsed_client_token.has_key?("displayName").should be_false
        parsed_client_token.has_key?("paypalPrivacyUrl").should be_false
        parsed_client_token.has_key?("paypalUserAgreementUrl").should be_false
        parsed_client_token.has_key?("paypalBaseUrl").should be_false
      end
    end
  end
end
