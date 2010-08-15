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

    def address
      AddressGateway.new(config)
    end

    def credit_card
      CreditCardGateway.new(config)
    end

    def customer
      CustomerGateway.new(config)
    end

    def subscription
      SubscriptionGateway.new(config)
    end

    def transparent_redirect
      TransparentRedirectGateway.new(config)
    end

    def transaction
      TransactionGateway.new(config)
    end
  end
end
