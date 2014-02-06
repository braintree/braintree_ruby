module Braintree
  class ClientTokenGateway
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def generate(options)
      @config.http.get("/client_token", options)[:client_token][:value]
    end
  end
end
