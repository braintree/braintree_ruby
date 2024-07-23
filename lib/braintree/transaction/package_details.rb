module Braintree
    class Transaction
        class PackageDetails
            include BaseModule

            attr_reader :carrier
            attr_reader :id
            # NEXT_MAJOR_VERSION Remove this method
            # use paypal_tracker_id going forward
            attr_reader :paypal_tracking_id
            attr_reader :paypal_tracker_id
            attr_reader :tracking_number

            def initialize(attributes)
              set_instance_variables_from_hash attributes unless attributes.nil?
            end
        end
    end
end