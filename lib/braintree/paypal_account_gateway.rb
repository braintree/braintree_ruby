module Braintree
  class PayPalAccountGateway
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def create(attributes)
      _do_create("/payment_methods", :paypal_account => attributes)
    end

    def _do_create(url, params=nil)
      response = @config.http.post url, params
      if response[:paypal_account]
        SuccessfulResult.new(:paypal_account => PayPalAccount._new(@gateway, response[:paypal_account]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :paypal_account or :api_error_response"
      end
    end
  end
end
