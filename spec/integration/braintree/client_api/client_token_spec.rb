require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/spec_helper")

describe Braintree::ClientToken do

  describe "self.generate" do
    it "generates a fingerprint that the gateway accepts" do
      config = Braintree::Configuration.instantiate
      client_token = Braintree::ClientToken.generate
      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => JSON.parse(client_token)["authorization_fingerprint"],
        :session_identifier => "fake_identifier",
        :session_identifier_type => "testing"
      )

      response = http.get_cards

      response.code.should == "200"
    end

    it "can pass verify_card" do
      config = Braintree::Configuration.instantiate
      result = Braintree::Customer.create
      client_token = Braintree::ClientToken.generate(
        :customer_id => result.customer.id,
        :verify_card => true
      )

      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => JSON.parse(client_token)["authorization_fingerprint"],
        :session_identifier => "fake_identifier",
        :session_identifier_type => "testing"
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
        :make_default => true
      )

      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => JSON.parse(client_token)["authorization_fingerprint"],
        :session_identifier => "fake_identifier",
        :session_identifier_type => "testing"
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
        :authorization_fingerprint => JSON.parse(client_token)["authorization_fingerprint"],
        :session_identifier => "fake_identifier",
        :session_identifier_type => "testing"
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
        :fail_on_duplicate_payment_method => true
      )

      http.fingerprint = JSON.parse(client_token)["authorization_fingerprint"]

      response = http.add_card(
        :credit_card => {
          :number => "4111111111111111",
          :expiration_month => "11",
          :expiration_year => "2099"
        }
      )

      response.code.should == "422"
    end
  end
end
