module Braintree
  class SepaDirectDebitAccountGateway
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
      @config.assert_has_access_token_or_keys
    end

    def find(token)
      raise ArgumentError if token.nil? || token.to_s.strip == ""
      response = @config.http.get("#{@config.base_merchant_path}/payment_methods/sepa_debit_account/#{token}")
      SepaDirectDebitAccount._new(@gateway, response[:sepa_debit_account])
    rescue NotFoundError
      raise NotFoundError, "sepa direct debit account with token #{token.inspect} not found"
    end

    def delete(token)
      raise ArgumentError if token.nil? || token.to_s.strip == ""
      @config.http.delete("#{@config.base_merchant_path}/payment_methods/sepa_debit_account/#{token}")
      SuccessfulResult.new
    rescue NotFoundError
      raise NotFoundError, "sepa direct debit account with token #{token.inspect} not found"
    end
  end
end
