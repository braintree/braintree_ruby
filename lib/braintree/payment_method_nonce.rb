module Braintree
  class PaymentMethodNonce
    include BaseModule # :nodoc:

    def self.create(payment_method_token)
      Configuration.gateway.payment_method_nonce.create(payment_method_token)
    end

    def self.find(payment_method_nonce)
      Configuration.gateway.payment_method_nonce.find(payment_method_nonce)
    end

    attr_reader :nonce, :three_d_secure_info, :type, :details, :bin_data

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      @nonce = attributes.fetch(:nonce)
      @type = attributes.fetch(:type)
      @details = attributes.fetch(:details)
      @three_d_secure_info = ThreeDSecureInfo.new(attributes[:three_d_secure_info]) if attributes[:three_d_secure_info]
      @bin_data = BinData.new(attributes[:bin_data]) if attributes[:bin_data]
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
