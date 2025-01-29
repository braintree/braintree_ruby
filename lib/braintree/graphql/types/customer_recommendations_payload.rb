# Represents the customer recommendations information associated with a PayPal customer session.

module Braintree
    class CustomerRecommendationsPayload
        include BaseModule

        attr_reader :attrs
        attr_reader :is_in_paypal_network
        attr_reader :recommendations

        def initialize(attributes)
            @attrs = [:is_in_paypal_network, :recommendations]
            @is_in_paypal_network = attributes[:isInPayPalNetwork] if attributes[:isInPayPalNetwork]
            @recommendations = CustomerRecommendations._new(attributes[:recommendations]) if attributes[:recommendations]
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


