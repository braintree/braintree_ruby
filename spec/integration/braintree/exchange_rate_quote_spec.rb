require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::ExchangeRateQuoteGateway do
  let(:gateway) do
    Braintree::Gateway.new(
      :environment => :development,
      :merchant_id => "integration_merchant_id",
      :public_key => "integration_public_key",
      :private_key => "integration_private_key",
    )
  end

  describe "generate" do
    def quote_input_request
      gateway.exchange_rate_quote.generate({quotes: [quote_input]})
    end

    let(:quote_input) do
      {
        :baseCurrency => "EUR",
        :quoteCurrency => "GBP",
        :baseAmount => "20.00",
        :markup => "4.00"
      }
    end

    it "generates exchange rate quotes" do
      result = quote_input_request
      quotes = result[:quotes]

      expect(quotes[0][:id]).not_to be_nil
      expect(quotes[0][:baseAmount]).not_to be_nil
      expect(quotes[0][:quoteAmount]).not_to be_nil
      expect(quotes[0][:exchangeRate]).not_to be_nil
      expect(quotes[0][:expiresAt]).not_to be_nil
      expect(quotes[0][:refreshesAt]).not_to be_nil

      expect(quotes[1][:id]).not_to be_nil
      expect(quotes[1][:baseAmount]).not_to be_nil
      expect(quotes[1][:quoteAmount]).not_to be_nil
      expect(quotes[1][:exchangeRate]).not_to be_nil
      expect(quotes[1][:expiresAt]).not_to be_nil
      expect(quotes[1][:refreshesAt]).not_to be_nil
    end

    context "when base currency input param is not passed" do
      let(:quote_input) do
        {
          :quoteCurrency => "GBP",
          :baseAmount => "20.00",
          :markup => "4.00"
        }
      end
      let(:error_message) { "baseCurrency" }

      it "raises an UnexpectedError" do
        expect do
          quote_input_request
        end.to raise_error(Braintree::UnexpectedError, /#{error_message}/)
      end
    end

    context "when quote currency input param is not passed" do
      let(:quote_input) do
        {
          :baseCurrency => "GBP",
          :baseAmount => "20.00",
          :markup => "4.00"
        }
      end
      let(:error_message) { "quoteCurrency" }

      it "raises an UnexpectedError" do
        expect do
          quote_input_request
        end.to raise_error(Braintree::UnexpectedError, /#{error_message}/)
      end
    end

    context "when base and quote currency input params are not passed" do
      let(:quote_input) do
        {
          :baseAmount => "20.00",
          :markup => "4.00"
        }
      end
      let(:error_message) { "baseCurrency" }

      it "raises an UnexpectedError" do
        expect do
          quote_input_request
        end.to raise_error(Braintree::UnexpectedError, /#{error_message}/)
      end
    end
  end
end
