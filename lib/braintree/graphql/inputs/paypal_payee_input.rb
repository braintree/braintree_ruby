#Experimental
# This class is experimental and may change in future releases.
module Braintree
    class PayPalPayeeInput
        include BaseModule

        attr_reader :attrs
        attr_reader :email_address
        attr_reader :client_id

        def initialize(attributes)
            @attrs = attributes.keys
            set_instance_variables_from_hash(attributes)
        end

        def inspect
            inspected_attributes = @attrs.map { |attr| "#{attr}:#{send(attr).inspect}" }
            "#<#{self.class} #{inspected_attributes.join(" ")}>"
        end

        def to_graphql_variables
            variables = {}
            variables["emailAddress"] = email_address if email_address
            variables["clientId"] = client_id if client_id
            variables
        end
    end
end