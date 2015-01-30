module Braintree
  class PaymentMethodNonce
    include BaseModule # :nodoc:

    def self.create(payment_method)
      Configuration.gateway.payment_method_nonce.create(payment_method)
    end

    attr_reader :nonce

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      @nonce = attributes.fetch(:nonce)
    end

    def to_s # :nodoc:
      nonce
    end

    class << self
      protected :new
    end

    def self._new(gateway, attributes) # :nodoc:
      new(gateway, attributes)
    end
  end
end
