require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe ::Braintree::ExchangeRate do
  let(:rate_quote) do
    {
      id: "1234",
      base_amount: "10.00",
      exchange_rate: "74",
      quote_amount: "740"
    }
  end

  describe "#initialize" do
    it "initialize and sets the attributes" do
      exchange_rate = described_class.new(:gateway, rate_quote).inspect

      expect(exchange_rate).to include("@id=\"1234\"")
      expect(exchange_rate).to include("@base_amount=\"10.00\"")
      expect(exchange_rate).to include("@exchange_rate=\"74\"")
      expect(exchange_rate).to include("@quote_amount=\"740\"")
    end
  end
end
