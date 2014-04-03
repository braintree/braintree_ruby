module Braintree
  class PayPalAccount
    include BaseModule

    attr_reader :email, :consent_code, :token

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
    end

    def self.create(attributes)
      Configuration.gateway.paypal_account.create(attributes)
    end

    def self._new(*args)
      self.new(*args)
    end
  end
end
