module Braintree
  class Webhook
    module Kind
      SubscriptionPastDue = "subscription_past_due"
    end

    def self.parse(signature, payload)
      Configuration.gateway.webhook.parse(signature, payload)
    end

    def self.sample_notification(kind, id)
      Configuration.gateway.webhook.sample_notification(kind, id)
    end

    def self.verify(challenge)
      Configuration.gateway.webhook.verify(challenge)
    end
  end
end
