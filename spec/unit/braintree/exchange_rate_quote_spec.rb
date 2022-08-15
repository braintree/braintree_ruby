require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::ExchangeRateQuote do
  let(:rate_quote) do
    {
      id: "1234",
      base_amount: "10.00",
      exchange_rate: "74",
      quote_amount: "740"
    }
  end

  describe "#initialize" do
    it "initialize and sets the input keys to attrs variable" do
      quote = described_class.new(rate_quote)

      expect(quote.attrs).to include(:id)
      expect(quote.attrs).to include(:base_amount)
      expect(quote.attrs).to include(:exchange_rate)
      expect(quote.attrs).to include(:quote_amount)
      expect(quote.attrs.length).to eq(4)
    end
  end

  describe "inspect" do
    it "includes the id first" do
      output = described_class.new(id: "1234").inspect

      expect(output).to include("#<Braintree::ExchangeRateQuote id:\"1234\">")
    end

    it "includes all quote attributes" do
      quote = described_class.new(rate_quote)
      output = quote.inspect

      expect(output).to include("id:\"1234\"")
      expect(output).to include("base_amount:\"10.00\"")
      expect(output).to include("exchange_rate:\"74\"")
      expect(output).to include("quote_amount:\"740\"")
    end
  end
end
