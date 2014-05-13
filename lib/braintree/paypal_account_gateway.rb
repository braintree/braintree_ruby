module Braintree
  class PayPalAccountGateway
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def find(token)
      raise ArgumentError if token.nil? || token.to_s.strip == ""
      response = @config.http.get "/payment_methods/paypal_account/#{token}"
      PayPalAccount._new(@gateway, response[:paypal_account])
    rescue NotFoundError
      raise NotFoundError, "payment method with token #{token.inspect} not found"
    end

    def update(token, attributes)
      # Util.verify_keys(PayPalAccountGateway._update_signature, attributes)
      _do_update(:put, "/payment_methods/paypal_account/#{token}", attributes)
    end

    def _do_update(http_verb, url, params) # :nodoc:
      response = @config.http.send http_verb, url, params
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
