require File.expand_path(File.dirname(__FILE__) + "/../../../spec_helper")

describe Braintree::BillingAddressInput do
  describe "#initialize" do
    it "initializes with all attributes" do
      attributes = {
        street_address: "123 Main St",
        extended_address: "Apt 4B",
        locality: "Mexico City",
        region: "CDMX",
        postal_code: "01000",
        country_code_alpha2: "MX"
      }
      input = Braintree::BillingAddressInput.new(attributes)

      expect(input.street_address).to eq("123 Main St")
      expect(input.extended_address).to eq("Apt 4B")
      expect(input.locality).to eq("Mexico City")
      expect(input.region).to eq("CDMX")
      expect(input.postal_code).to eq("01000")
      expect(input.country_code_alpha2).to eq("MX")
    end
  end

  describe "#to_graphql_variables" do
    it "converts to graphql variables with camelCase keys" do
      attributes = {
        street_address: "123 Main St",
        locality: "Mexico City",
        postal_code: "01000",
        country_code_alpha2: "MX"
      }
      input = Braintree::BillingAddressInput.new(attributes)
      expected_variables = {
        "streetAddress" => "123 Main St",
        "locality" => "Mexico City",
        "postalCode" => "01000",
        "countryCode" => "MX"
      }

      expect(input.to_graphql_variables).to eq(expected_variables)
    end

    it "omits nil values" do
      attributes = {street_address: "123 Main St"}
      input = Braintree::BillingAddressInput.new(attributes)
      expected_variables = {"streetAddress" => "123 Main St"}

      expect(input.to_graphql_variables).to eq(expected_variables)
    end
  end

  describe "#inspect" do
    it "returns formatted string" do
      attributes = {
        street_address: "123 Main St",
        locality: "Mexico City",
        postal_code: "01000"
      }
      input = Braintree::BillingAddressInput.new(attributes)
      result = input.inspect

      expect(result).to include("BillingAddressInput")
      expect(result).to include("street_address:")
      expect(result).to include("locality:")
    end
  end
end
