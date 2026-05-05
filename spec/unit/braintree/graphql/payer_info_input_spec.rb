require File.expand_path(File.dirname(__FILE__) + "/../../../spec_helper")

describe Braintree::PayerInfoInput do
  describe "#initialize" do
    it "initializes with all attributes" do
      attributes = {
        given_name: "John",
        surname: "Doe",
        phone_country_code: "+351",
        phone_number: "912345678",
        billing_address: {
          street_address: "123 Main St",
          locality: "Lisbon"
        }
      }
      input = Braintree::PayerInfoInput.new(attributes)

      expect(input.given_name).to eq("John")
      expect(input.surname).to eq("Doe")
      expect(input.phone_country_code).to eq("+351")
      expect(input.phone_number).to eq("912345678")
      expect(input.billing_address).to be_a(Braintree::BillingAddressInput)
    end

    it "handles nil billing_address" do
      attributes = {given_name: "John", surname: "Doe"}
      input = Braintree::PayerInfoInput.new(attributes)
      expect(input.billing_address).to be_nil
    end
  end

  describe "#to_graphql_variables" do
    it "converts to graphql variables with camelCase keys" do
      attributes = {
        given_name: "John",
        surname: "Doe",
        phone_country_code: "+351",
        phone_number: "912345678"
      }
      input = Braintree::PayerInfoInput.new(attributes)
      expected_variables = {
        "givenName" => "John",
        "phoneCountryCode" => "+351",
        "phoneNumber" => "912345678",
        "surname" => "Doe"
      }

      expect(input.to_graphql_variables).to eq(expected_variables)
    end

    it "includes nested billing_address" do
      attributes = {
        given_name: "John",
        surname: "Doe",
        billing_address: {
          street_address: "123 Main St",
          postal_code: "1000-001"
        }
      }
      input = Braintree::PayerInfoInput.new(attributes)
      variables = input.to_graphql_variables

      expect(variables["billingAddress"]).to be_a(Hash)
      expect(variables["billingAddress"]["streetAddress"]).to eq("123 Main St")
      expect(variables["billingAddress"]["postalCode"]).to eq("1000-001")
    end

    it "omits nil values" do
      attributes = {given_name: "John"}
      input = Braintree::PayerInfoInput.new(attributes)
      expected_variables = {"givenName" => "John"}

      expect(input.to_graphql_variables).to eq(expected_variables)
    end
  end

  describe "#inspect" do
    it "returns formatted string" do
      attributes = {
        given_name: "John",
        surname: "Doe",
        email: "john@example.com"
      }
      input = Braintree::PayerInfoInput.new(attributes)
      result = input.inspect

      expect(result).to include("PayerInfoInput")
      expect(result).to include("given_name:")
      expect(result).to include("surname:")
    end
  end
end
