module Braintree
  class PayPalAccount
    include BaseModule

    attr_reader :email, :consent_code, :token

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
    end

    class << self
      protected :new
    end

    def self._new(*args)
      self.new(*args)
    end

    def self.find(token)
      Configuration.gateway.paypal_account.find(token)
    end

    def self.update(token, attributes)
      Configuration.gateway.paypal_account.update(token, attributes)
    end

    # Returns true if this paypal account is the customer's default payment method.
    def default?
      @default
    end
  end
end
