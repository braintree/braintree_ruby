require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::MonetaryAmount do
  describe "#initialize" do
    it "initializes with value and currency_code" do
      amount = Braintree::MonetaryAmount._new(
        value: "10.00",
        currency_code: "USD",
      )

      expect(amount.value).to eq("10.00")
      expect(amount.currency_code).to eq("USD")
    end
  end

  describe "#inspect" do
    it "returns formatted string representation" do
      amount = Braintree::MonetaryAmount._new(
        value: "25.50",
        currency_code: "EUR",
      )

      expect(amount.inspect).to eq('#<MonetaryAmount currency_code:"EUR" value:"25.50">')
    end
  end

  describe "self.new" do
    it "is protected" do
      expect do
        Braintree::MonetaryAmount.new
      end.to raise_error(NoMethodError, /protected method .new/)
    end
  end
end
