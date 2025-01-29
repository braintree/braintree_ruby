# A union of all possible customer recommendations associated with a PayPal customer session.

module Braintree
    class CustomerRecommendations
        include BaseModule

        attr_reader :attrs
        attr_reader :payment_options

        def initialize(attributes)
            @attrs = [:payment_options]
            if attributes.nil?
                @payment_options = []
            else
                @payment_options = (attributes[:paymentOptions] || []).map { |payment_options_hash| PaymentOptions._new(payment_options_hash) }
            end
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


