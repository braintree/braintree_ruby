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
      elsif response[:sepa_bank_account]
        SuccessfulResult.new(:payment_method => SEPABankAccount._new(@gateway, response[:sepa_bank_account]))
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
      elsif response.has_key?(:sepa_bank_account)
        SEPABankAccount._new(@gateway, response[:sepa_bank_account])
      else
        UnknownPaymentMethod.new(response)
      end
    rescue NotFoundError
      raise NotFoundError, "payment method with token #{token.inspect} not found"
    end

    def self._create_signature # :nodoc:
      billing_address_params = AddressGateway._shared_signature
      options = [
        :make_default,
        :verify_card,
        :fail_on_duplicate_payment_method,
        :verification_merchant_account_id
      ]
      [
        :customer_id,
        :payment_method_nonce,
        :token,
        {:options => options},
        {:billing_address => billing_address_params}
      ]
    end
  end
end
