module Braintree
  class PaymentMethod
    include BaseModule

    attr_reader :email, :consent_code, :token

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
    end

    def self.create(attributes)
      Configuration.gateway.payment_method.create(attributes)
    end

    def self.find(token)
      Configuration.gateway.payment_method.find(token)
    end

    def self._new(*args)
      self.new(*args)
    end
  end
end
