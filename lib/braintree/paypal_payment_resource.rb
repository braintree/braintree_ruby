module Braintree
    class PayPalPaymentResource
        include BaseModule

        def self.update(*args)
            Configuration.gateway.paypal_payment_resource.update(*args)
        end

        class << self
            protected :new
            def _new(*args)
              self.new(*args)
            end
        end

        def initialize(gateway, attributes)
            @gateway = gateway
            set_instance_variables_from_hash(attributes)
        end
    end
end

