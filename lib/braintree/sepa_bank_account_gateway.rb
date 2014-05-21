module Braintree
  class SEPABankAccountGateway
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def find(token)
      raise ArgumentError if token.nil? || token.to_s.strip == ""
      response = @config.http.get "/payment_methods/sepa_bank_account/#{token}"
      SEPABankAccount._new(@gateway, response[:sepa_bank_account])
    rescue NotFoundError
      raise NotFoundError, "payment method with token #{token.inspect} not found"
    end
  end
end
