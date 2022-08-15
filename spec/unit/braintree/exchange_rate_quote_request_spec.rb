require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::ExchangeRateQuoteRequest do
  describe "#initialize" do
    it "creates and validates the exchange rate quote request" do
      req = Braintree::ExchangeRateQuoteRequest.new(
          :quotes => [
            {
              :base_currency => "USD",
              :quote_currency => "EUR",
              :base_amount => "10.00",
              :markup => "2.00"
            },
            {
              :base_currency => "EUR",
              :quote_currency => "GBP",
              :base_amount => "20.00",
              :markup => "4.00"
            }
          ],
      )

      expect(req.quotes[0].base_currency).to eq("USD")
      expect(req.quotes[0].quote_currency).to eq("EUR")
      expect(req.quotes[0].base_amount).to eq("10.00")
      expect(req.quotes[0].markup).to eq("2.00")

      expect(req.quotes[1].base_currency).to eq("EUR")
      expect(req.quotes[1].quote_currency).to eq("GBP")
      expect(req.quotes[1].base_amount).to eq("20.00")
      expect(req.quotes[1].markup).to eq("4.00")
    end

    it "creates and validates the exchange rate quote request without amount and markup" do
      req = Braintree::ExchangeRateQuoteRequest.new(
          :quotes => [
            {
              :base_currency => "USD",
              :quote_currency => "EUR",
            },
            {
              :base_currency => "EUR",
              :quote_currency => "GBP",
            }
          ],
      )

      expect(req.quotes[0].base_currency).to eq("USD")
      expect(req.quotes[0].quote_currency).to eq("EUR")
      expect(req.quotes[0].base_amount).to be_nil
      expect(req.quotes[0].markup).to be_nil

      expect(req.quotes[1].base_currency).to eq("EUR")
      expect(req.quotes[1].quote_currency).to eq("GBP")
      expect(req.quotes[1].base_amount).to be_nil
      expect(req.quotes[1].markup).to be_nil
    end

  end

  describe "inspect" do
    it "prints the attributes" do
      exchange_rate_req = Braintree::ExchangeRateQuoteRequest.new(
          :quotes => [
            {
              :base_currency => "USD",
              :quote_currency => "EUR",
              :base_amount => "10.00",
              :markup => "2.00"
            },
            {
              :base_currency => "EUR",
              :quote_currency => "GBP",
              :base_amount => "20.00",
              :markup => "4.00"
            }
          ],
      )
      expect(exchange_rate_req.inspect).to eq(%(#<Braintree::ExchangeRateQuoteRequest quotes:[#<Braintree::ExchangeRateQuoteInput base_currency:"USD" quote_currency:"EUR" base_amount:"10.00" markup:"2.00">, #<Braintree::ExchangeRateQuoteInput base_currency:"EUR" quote_currency:"GBP" base_amount:"20.00" markup:"4.00">]>))
    end
  end
end
