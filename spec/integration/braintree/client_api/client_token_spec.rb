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

      response = http.get_payment_methods

      response.code.should == "200"
    end

    it "raises ArgumentError on invalid parameters (422)" do
      expect do
        Braintree::ClientToken.generate(:options => {:make_default => true})
      end.to raise_error(ArgumentError)
    end

    it "allows a client token version to be specified" do
      config = Braintree::Configuration.instantiate
      client_token = Braintree::ClientToken.generate(:version => 1)
      client_token.should =~ /"version":1/
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

      response = http.add_payment_method(
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

      response = http.add_payment_method(
        :credit_card => {
          :number => "4111111111111111",
          :expiration_month => "11",
          :expiration_year => "2099"
        }
      )

      response.code.should == "201"

      response = http.add_payment_method(
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

      response = http.add_payment_method(
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

      response = http.add_payment_method(
        :credit_card => {
          :number => "4111111111111111",
          :expiration_month => "11",
          :expiration_year => "2099"
        }
      )

      response.code.should == "422"
    end

    it "can pass merchant_account_id" do
      client_token = Braintree::ClientToken.generate(
        :merchant_account_id => "my_merchant_account"
      )

      parsed_client_token = JSON.parse(client_token)
      parsed_client_token["merchantAccountId"].should == "my_merchant_account"
    end
  end
end
