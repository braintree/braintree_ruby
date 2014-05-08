module Braintree
  class PayPalAccount
    include BaseModule

    attr_reader :email, :consent_code, :token

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
    end

    def self._new(*args)
      self.new(*args)
    end

    def self.find(token)
      Configuration.gateway.paypal_account.find(token)
    end
  end
end
