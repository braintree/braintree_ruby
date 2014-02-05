module Braintree
  class ClientTokenGateway
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def generate(options)
      path = "/client_token"

      if options.any?
        path += "?#{URI.encode_www_form(options)}"
      end

      @config.http.get(path)[:client_token][:value]
    end
  end
end
