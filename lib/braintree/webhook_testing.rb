module Braintree
  class WebhookTesting
    def self.sample_notification(*args)
      Configuration.gateway.webhook_testing.sample_notification(*args)
    end
  end
end
