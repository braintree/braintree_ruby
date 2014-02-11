module Braintree
  class ClientTokenGateway
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def generate(options={})
      params = options.any? ? {:client_token => options} : nil
      result = @config.http.post("/client_token", params)

      if result[:client_token]
        result[:client_token][:value]
      else
        raise ArgumentError, result[:api_error_response][:message]
      end
    end
  end
end
