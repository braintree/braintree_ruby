module Braintree
  class MerchantGateway
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def create(params)
      _create_merchant(params)
    end

    def _create_merchant(params)
      response = @config.http.post("/merchants/create_via_api", :merchant => params)

      if response.has_key?(:response) && response[:response][:merchant]
        Braintree::SuccessfulResult.new(
          :merchant => Merchant._new(response[:response][:merchant]),
          :credentials => OAuthCredentials._new(response[:response][:credentials]),
        )
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise "expected :merchant or :api_error_response"
      end
    end
  end
end
