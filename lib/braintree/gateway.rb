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
      AddressGateway.new(self)
    end

    def credit_card
      CreditCardGateway.new(self)
    end

    def customer
      CustomerGateway.new(self)
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
  end
end
