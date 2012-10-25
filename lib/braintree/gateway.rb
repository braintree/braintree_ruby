module Braintree
  class Gateway # :nodoc:
    attr_reader :config

    def initialize(config)
      if config.is_a?(Hash)
        @config = Configuration.new config
      elsif config.is_a?(Braintree::Configuration)
        @config = config
      else
        raise ArgumentError, "config is an invalid type"
      end
    end

    def add_on
      AddOnGateway.new(self)
    end

    def address
      AddressGateway.new(self)
    end

    def credit_card
      CreditCardGateway.new(self)
    end

    def customer
      CustomerGateway.new(self)
    end

    def discount
      DiscountGateway.new(self)
    end

    def plan
      PlanGateway.new(self)
    end

    def settlement_batch_summary
      SettlementBatchSummaryGateway.new(self)
    end

    def subscription
      SubscriptionGateway.new(self)
    end

    def transparent_redirect
      TransparentRedirectGateway.new(self)
    end

    def transaction
      TransactionGateway.new(self)
    end

    def verification
      CreditCardVerificationGateway.new(self)
    end

    def webhook_notification
      WebhookNotificationGateway.new(self)
    end

    def webhook_testing
      WebhookTestingGateway.new(self)
    end
  end
end
