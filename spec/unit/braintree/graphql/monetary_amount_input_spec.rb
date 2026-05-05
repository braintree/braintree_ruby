require File.expand_path(File.dirname(__FILE__) + "/../../../spec_helper")

describe Braintree::MonetaryAmountInput do
  describe "#initialize" do
    it "initializes with all attributes" do
      attributes = {
        value: "10.00",
        currency_code: "USD"
      }
      input = Braintree::MonetaryAmountInput.new(attributes)

      expect(input.value).to eq("10.00")
      expect(input.currency_code).to eq("USD")
    end
  end

  describe "#to_graphql_variables" do
    it "converts to graphql variables with camelCase keys" do
      attributes = {
        value: "25.50",
        currency_code: "EUR"
      }
      input = Braintree::MonetaryAmountInput.new(attributes)
      expected_variables = {
        "value" => "25.50",
        "currencyCode" => "EUR"
      }

      expect(input.to_graphql_variables).to eq(expected_variables)
    end

    it "omits nil values" do
      attributes = {value: "10.00"}
      input = Braintree::MonetaryAmountInput.new(attributes)
      expected_variables = {"value" => "10.00"}

      expect(input.to_graphql_variables).to eq(expected_variables)
    end
  end

  describe "#inspect" do
    it "returns formatted string" do
      attributes = {
        value: "25.50",
        currency_code: "EUR"
      }
      input = Braintree::MonetaryAmountInput.new(attributes)
      result = input.inspect

      expect(result).to include("MonetaryAmountInput")
      expect(result).to include("value:")
      expect(result).to include("currency_code:")
    end
  end
end
