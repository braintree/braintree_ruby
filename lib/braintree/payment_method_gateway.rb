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
      elsif response[:coinbase_account]
        SuccessfulResult.new(:payment_method => CoinbaseAccount._new(@gateway, response[:coinbase_account]))
      elsif response[:europe_bank_account]
        SuccessfulResult.new(:payment_method => EuropeBankAccount._new(@gateway, response[:europe_bank_account]))
      elsif response[:apple_pay_card]
        SuccessfulResult.new(:payment_method => ApplePayCard._new(@gateway, response[:apple_pay_card]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      elsif response
        SuccessfulResult.new(:payment_method => UnknownPaymentMethod._new(@gateway, response))
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
      elsif response[:coinbase_account]
        SuccessfulResult.new(:payment_method => CoinbaseAccount._new(@gateway, response[:coinbase_account]))
      elsif response.has_key?(:europe_bank_account)
        EuropeBankAccount._new(@gateway, response[:europe_bank_account])
      elsif response.has_key?(:apple_pay_card)
        ApplePayCard._new(@gateway, response[:apple_pay_card])
      else
        UnknownPaymentMethod._new(@gateway, response)
      end
    rescue NotFoundError
      raise NotFoundError, "payment method with token #{token.inspect} not found"
    end

    def update(token, attributes)
      Util.verify_keys(PaymentMethodGateway._update_signature, attributes)
      _do_update(:put, "/payment_methods/any/#{token}", :payment_method => attributes)
    end

    def _do_update(http_verb, url, params) # :nodoc:
      response = @config.http.send http_verb, url, params
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

    def self._create_signature # :nodoc:
      _signature(:create)
    end

    def self._update_signature # :nodoc:
      _signature(:update)
    end

    def self._signature(type) # :nodoc:
      billing_address_params = AddressGateway._shared_signature
      options = [:make_default, :verification_merchant_account_id, :verify_card, :venmo_sdk_session]
      signature = [
        :billing_address_id, :cardholder_name, :cvv, :device_session_id, :expiration_date,
        :expiration_month, :expiration_year, :number, :token, :venmo_sdk_payment_method_code,
        :device_data, :fraud_merchant_id, :payment_method_nonce,
        {:options => options},
        {:billing_address => billing_address_params}
      ]

      case type
      when :create
        options << :fail_on_duplicate_payment_method
        signature << :customer_id
      when :update
        billing_address_params << {:options => [:update_existing]}
      else
        raise ArgumentError
      end

      return signature
    end
  end
end
