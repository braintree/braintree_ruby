module Braintree
    class Transaction
        class PackageDetails
            include BaseModule

            attr_reader :carrier
            attr_reader :id
            attr_reader :paypal_tracking_id
            attr_reader :tracking_number

            def initialize(attributes)
                set_instance_variables_from_hash attributes unless attributes.nil?
            end
        end
    end
end