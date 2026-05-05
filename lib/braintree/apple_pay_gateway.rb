module Braintree
  class ApplePayGateway
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def register_domain(domain)
      response = @config.http.post("#{@config.base_merchant_path}/processing/apple_pay/validate_domains", :url => domain)

      if response.has_key?(:response) && response[:response][:success]
        Braintree::SuccessfulResult.new
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise "expected :response or :api_error_response"
      end
    end

    def unregister_domain(domain)
      @config.http.delete("#{@config.base_merchant_path}/processing/apple_pay/unregister_domain", :url => CGI.escape(domain))
      SuccessfulResult.new
    end

    def registered_domains
      response = @config.http.get("#{@config.base_merchant_path}/processing/apple_pay/registered_domains")

      if response.has_key?(:response)
        Braintree::SuccessfulResult.new(:apple_pay_options => ApplePayOptions._new(response[:response]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise "expected :response or :api_error_response"
      end
    end

    def self._card_signature(type)
      billing_address_params = AddressGateway._shared_signature

      options = [
        :verification_account_type,
        :verification_amount,
        :verification_merchant_account_id,
        :verify_card
      ]

      signature = [
        :cardholder_name,
        :cryptogram,
        :eci_indicator,
        :expiration_month,
        :expiration_year,
        :network_transaction_id,
        :number,
        :token,
        {:billing_address => billing_address_params},
        {:options => options}
      ]

      case type
      when :create
        nil
      when :update
        options << :make_default
      else
        raise ArgumentError, "Invalid signature type: #{type}"
      end

      signature
    end

    def self._create_card_signature
      _card_signature(:create)
    end

    def self._update_card_signature
      _card_signature(:update)
    end
  end
end
