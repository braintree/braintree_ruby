# Represents the input to request the creation of a PayPal customer session.

module Braintree
    class CreateCustomerSessionInput
        include BaseModule

        attr_reader :attrs
        attr_reader :merchant_account_id
        attr_reader :session_id
        attr_reader :customer
        attr_reader :domain

        def initialize(attributes)
            @attrs = attributes.keys
            set_instance_variables_from_hash(attributes)
            @customer = attributes[:customer] ? CustomerSessionInput.new(attributes[:customer]) : nil
        end

        def inspect
            inspected_attributes = @attrs.map { |attr| "#{attr}:#{send(attr).inspect}" }
            "#<#{self.class} #{inspected_attributes.join(" ")}>"
        end

        def to_graphql_variables
            variables = {}
            variables["merchantAccountId"] = merchant_account_id if merchant_account_id
            variables["sessionId"] = session_id if session_id
            variables["domain"] = domain if domain
            variables["customer"] = customer.to_graphql_variables if customer
            variables
        end
    end
end


