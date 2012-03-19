module Braintree
  class WebhookNotification
    include BaseModule

    module Kind
      SubscriptionCanceled = "subscription_canceled"
      SubscriptionChargedSuccessfully = "subscription_charged_successfully"
      SubscriptionChargedUnsuccessfully = "subscription_charged_unsuccessfully"
      SubscriptionExpired = "subscription_expired"
      SubscriptionTrialEnded = "subscription_trial_ended"
      SubscriptionWentActive = "subscription_went_active"
      SubscriptionWentPastDue = "subscription_went_past_due"
    end

    attr_reader :subscription, :kind, :timestamp

    def self.parse(signature, payload)
      Configuration.gateway.webhook_notification.parse(signature, payload)
    end

    def self.verify(challenge)
      Configuration.gateway.webhook_notification.verify(challenge)
    end

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @subscription = Subscription._new(gateway, @subject[:subscription]) if @subject.has_key?(:subscription)
    end

    class << self
      protected :new
      def _new(*args) # :nodoc:
        self.new *args
      end
    end
  end
end
