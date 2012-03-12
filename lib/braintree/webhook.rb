module Braintree
  class Webhook
    def self.parse(signature, payload)
      Configuration.gateway.webhook.parse(signature, payload)
    end

    def self.verify(challenge)
      Configuration.gateway.webhook.verify(challenge)
    end
  end
end
