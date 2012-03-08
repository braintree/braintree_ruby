module Braintree
  class WebhookGateway # :nodoc:
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def verify(challenge)
      digest = Braintree::Digest.hexdigest(@config.private_key, challenge)
      "#{@config.public_key}|#{digest}"
    end
  end
end
