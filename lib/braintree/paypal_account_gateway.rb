module Braintree
  class PayPalAccountGateway
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def find(token)
      raise ArgumentError if token.nil? || token.to_s.strip == ""
      response = @config.http.get "/payment_methods/#{token}"
      PayPalAccount._new(@gateway, response[:paypal_account])
    rescue NotFoundError
      raise NotFoundError, "payment method with token #{token.inspect} not found"
    end
  end
end
