module Braintree
  class PaymentMethodNonceGateway # :nodoc:
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def create(payment_method_token)
      response = @config.http.post("#{@config.base_merchant_path}/payment_methods/#{payment_method_token}/nonces")
      payment_method_nonce = PaymentMethodNonce._new(@gateway, response.fetch(:payment_method_nonce))
      SuccessfulResult.new(:payment_method_nonce => payment_method_nonce)
    end

    def find(payment_method_nonce)
      response = @config.http.get("#{@config.base_merchant_path}/payment_method_nonces/#{payment_method_nonce}")
      payment_method_nonce = PaymentMethodNonce._new(@gateway, response.fetch(:payment_method_nonce))
      SuccessfulResult.new(:payment_method_nonce => payment_method_nonce)
    end
  end
end
