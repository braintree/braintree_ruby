require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::ExchangeRateQuoteInput do
  let(:exchange_rate_quote_input) do
    {
      base_currency: "USD",
      quote_currency: "EUR",
      base_amount: "10.00",
      markup: "2.00"
    }
  end

  describe "#initialize" do
    it "initialize and sets the input keys to attrs variable" do
      quote_input = described_class.new(exchange_rate_quote_input)

      expect(quote_input.attrs).to include(:base_currency)
      expect(quote_input.attrs).to include(:quote_currency)
      expect(quote_input.attrs).to include(:base_amount)
      expect(quote_input.attrs).to include(:markup)
      expect(quote_input.attrs.length).to eq(4)
    end
  end

  describe "inspect" do
    it "includes the base_currency first" do
      output = described_class.new(base_currency: "USD").inspect

      expect(output).to include("#<Braintree::ExchangeRateQuoteInput base_currency:\"USD\">")
    end

    it "includes all quote input attributes" do
      quote_input = described_class.new(exchange_rate_quote_input)
      output = quote_input.inspect

      expect(output).to include("base_currency:\"USD\"")
      expect(output).to include("quote_currency:\"EUR\"")
      expect(output).to include("base_amount:\"10.00\"")
      expect(output).to include("markup:\"2.00\"")
    end
  end
end
