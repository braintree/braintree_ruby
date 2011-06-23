module Braintree
  class PayerAuthenticationGateway # :nodoc:
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def authenticate(payer_authentication_id, response_payload)
      response = @config.http.post(
        "/payer_authentications/#{payer_authentication_id}/authenticate",
        :payer_authentication => {
          :response_payload => response_payload
        }
      )

      if response[:transaction]
        SuccessfulResult.new(:transaction => Transaction._new(@gateway, response[:transaction]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :transaction or :api_error_response"
      end
    end
  end
end
