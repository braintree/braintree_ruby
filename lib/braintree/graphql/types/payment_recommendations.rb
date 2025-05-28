# Represents the payment method and priority associated with a PayPal customer session.

#Experimental
# This class is experimental and may change in future releases.
module Braintree
    class PaymentRecommendations
        include BaseModule

        attr_reader :attrs
        attr_reader :payment_option
        attr_reader :recommended_priority

        def initialize(attributes)
            @attrs = [:payment_option, :recommended_priority]
            @payment_option = attributes[:paymentOption] if attributes[:paymentOption]
            @recommended_priority = attributes[:recommendedPriority] if attributes[:recommendedPriority]

        end

        def inspect
            inspected_attributes = @attrs.map { |attr| "#{attr}:#{send(attr).inspect}" }
            "#<#{self.class} #{inspected_attributes.join(" ")}>"
        end

        class << self
            protected :new
        end

        def self._new(*args)
            self.new(*args)
        end
    end
end


