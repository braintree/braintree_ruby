module Braintree
  class Webhook
    def self.verify(challenge)
      Configuration.gateway.webhook.verify(challenge)
    end
  end
end
