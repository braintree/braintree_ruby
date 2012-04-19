module Braintree
  class WebhookTesting # :nodoc:
    def self.sample_notification(kind, id)
      Configuration.gateway.webhook_testing.sample_notification(kind, id)
    end
  end
end
