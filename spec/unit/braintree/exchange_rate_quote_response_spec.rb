require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::ExchangeRateQuoteResponse do
  describe "#initialize" do
    it "creates and validated the exchange rate quote payload" do
      quote_payload = Braintree::ExchangeRateQuoteResponse.new(
        quotes: [
          {
            :base_amount => "10.00",
            :quote_amount => "9.03",
            :exchange_rate => "0.90"
          },
          {
            :base_amount => "20.00",
            :quote_amount => "18.06",
            :exchange_rate => "0.90"
          }
        ],
      )

      quote_1 = quote_payload.quotes[0]
      quote_2 = quote_payload.quotes[1]

      expect(quote_1.base_amount).to eq("10.00")
      expect(quote_1.quote_amount).to eq("9.03")
      expect(quote_1.exchange_rate).to eq("0.90")

      expect(quote_2.base_amount).to eq("20.00")
      expect(quote_2.quote_amount).to eq("18.06")
      expect(quote_1.exchange_rate).to eq("0.90")
    end
  end

  describe "inspect" do
    it "prints the attributes" do
      exchange_rate_quote_payload = Braintree::ExchangeRateQuoteResponse.new(
        quotes: [
          {
            :base_amount => "10.00",
            :quote_amount => "9.03"
          },
          {
            :base_amount => "20.00",
            :quote_amount => "18.06"
          }
        ],
      )

      expect(exchange_rate_quote_payload.inspect).to eq(%(#<Braintree::ExchangeRateQuoteResponse quotes:[#<Braintree::ExchangeRateQuote base_amount:"10.00" quote_amount:"9.03">, #<Braintree::ExchangeRateQuote base_amount:"20.00" quote_amount:"18.06">]>))
    end
  end
end
