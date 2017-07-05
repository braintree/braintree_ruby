module Braintree
  class ApplePayGateway
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def register_domain(domain)
      response = @config.http.post("#{@config.base_merchant_path}/processing/apple_pay/validate_domains", :url => domain)

      if response.has_key?(:response) && response[:response][:success]
        Braintree::SuccessfulResult.new()
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise "expected :response or :api_error_response"
      end
    end
  end
end
