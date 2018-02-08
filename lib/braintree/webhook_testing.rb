module Braintree
  class WebhookTesting # :nodoc:
    def self.sample_notification(kind, id, source_merchant_id=nil)
      Configuration.gateway.webhook_testing.sample_notification(kind, id, source_merchant_id)
    end
  end
end
