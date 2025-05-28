# Represents the input to request an update to a PayPal customer session.

#Experimental
# This class is experimental and may change in future releases.
module Braintree
    class UpdateCustomerSessionInput
        include BaseModule

        attr_reader :attrs
        attr_reader :merchant_account_id
        attr_reader :session_id
        attr_reader :customer
        attr_reader :purchase_units

        def initialize(attributes)
            unless attributes[:session_id]
                raise ArgumentError, "Expected hash to contain a :session_id"
            end
            @attrs = attributes.keys
            set_instance_variables_from_hash(attributes)
            @customer = attributes[:customer] ? CustomerSessionInput.new(attributes[:customer]) : nil
            @purchase_units = attributes[:purchase_units] ? attributes[:purchase_units].map { |pu| PayPalPurchaseUnitInput.new(pu) } : nil
        end

        def inspect
            inspected_attributes = @attrs.map { |attr| "#{attr}:#{send(attr).inspect}" }
            "#<#{self.class} #{inspected_attributes.join(" ")}>"
        end

        def to_graphql_variables
            variables = {}
            variables["merchantAccountId"] = merchant_account_id if merchant_account_id
            variables["sessionId"] = session_id if session_id
            variables["customer"] = customer.to_graphql_variables if customer
            variables["purchaseUnits"] = purchase_units.map(&:to_graphql_variables) if purchase_units
            variables
        end

    end
end


