module Braintree
  class ClientTokenGateway
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def generate(options={})
      params = nil
      if options
        Util.verify_keys(ClientTokenGateway._generate_signature, options)
        params = {:client_token => options}
      end
      result = @config.http.post("/client_token", params)

      if result[:client_token]
        result[:client_token][:value]
      else
        raise ArgumentError, result[:api_error_response][:message]
      end
    end

    def self._generate_signature # :nodoc:
      [
        :customer_id, :proxy_merchant_id, :merchant_account_id, :version,
        {:options => [:make_default, :verify_card, :fail_on_duplicate_payment_method]}
      ]
    end
  end
end
