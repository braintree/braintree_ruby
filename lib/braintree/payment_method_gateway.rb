module Braintree
  class PaymentMethodGateway # :nodoc:
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def create(attributes)
      Util.verify_keys(PaymentMethodGateway._create_signature, attributes)
      _do_create("/payment_methods", :payment_method => attributes)
    end

    def _do_create(url, params=nil) # :nodoc:
      response = @config.http.post url, params
      if response[:credit_card]
        SuccessfulResult.new(:payment_method => CreditCard._new(@gateway, response[:credit_card]))
      elsif response[:paypal_account]
        SuccessfulResult.new(:payment_method => PayPalAccount._new(@gateway, response[:paypal_account]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :payment_method or :api_error_response"
      end
    end

    def delete(token)
      @config.http.delete("/payment_methods/any/#{token}")
    end

    def find(token)
      raise ArgumentError if token.nil? || token.to_s.strip == ""
      response = @config.http.get "/payment_methods/any/#{token}"
      if response.has_key?(:credit_card)
        CreditCard._new(@gateway, response[:credit_card])
      elsif response.has_key?(:paypal_account)
        PayPalAccount._new(@gateway, response[:paypal_account])
      end
    rescue NotFoundError
      raise NotFoundError, "payment method with token #{token.inspect} not found"
    end

    def update(token, attributes)
      # Util.verify_keys(PaymentMethodGateway._update_signature, attributes)
      _do_update(:put, "/payment_methods/any/#{token}", attributes)
    end

    def _do_update(http_verb, url, params) # :nodoc:
      response = @config.http.send http_verb, url, params
      # if response[:credit_card]
      #   SuccessfulResult.new(:credit_card => CreditCard._new(@gateway, response[:credit_card]))
      if response[:paypal_account]
        SuccessfulResult.new(:paypal_account => PayPalAccount._new(@gateway, response[:paypal_account]))
      # elsif response[:api_error_response]
      #   ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :credit_card, :paypal_account, or :api_error_response"
      end
    end

    def self._create_signature # :nodoc:
      [:customer_id, :payment_method_nonce]
    end
  end
end
