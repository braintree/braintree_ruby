module Braintree
  class MerchantGateway # :nodoc:
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def provision_raw_apple_pay
      response = @config.http.put "/provision_raw_apple_pay"
      if response[:apple_pay]
        SuccessfulResult.new(response[:apple_pay])
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :apple_pay or :api_error_response"
      end
    end
  end
end
