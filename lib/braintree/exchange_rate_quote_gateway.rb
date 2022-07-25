module Braintree
  class ExchangeRateQuoteGateway # :nodoc
    def initialize(gateway)
      @gateway = gateway
    end

    DEFINITION = <<-GRAPHQL
      mutation GenerateExchangeRateQuoteInput($input: GenerateExchangeRateQuoteInput!) {
        generateExchangeRateQuote(input: $input) {
          quotes {
            id
            baseAmount {value, currencyCode}
            quoteAmount {value, currencyCode}
            exchangeRate
            tradeRate
            expiresAt
            refreshesAt
          }
        }
      }
    GRAPHQL

    def generate(params)
      response = @gateway.config.graphql_client.query(DEFINITION, {input: params})

      if response.has_key?(:data) && response[:data][:generateExchangeRateQuote]
        response[:data][:generateExchangeRateQuote]
      elsif response[:errors]
        ErrorResult.new(@gateway, response[:errors])
      else
        raise UnexpectedError, "expected :generateExchangeRateQuote or :api_error_response in GraphQL response"
      end
    end
  end
end
