# Represents the input to request the creation of a PayPal customer session.

#Experimental
# This class is experimental and may change in future releases.
module Braintree
    class CreateCustomerSessionInput
        include BaseModule

        attr_reader :attrs
        attr_reader :merchant_account_id
        attr_reader :session_id
        attr_reader :customer
        attr_reader :domain
        attr_reader :purchase_units

        def initialize(attributes)
            @attrs = attributes.keys
            set_instance_variables_from_hash(attributes)
            @customer = attributes[:customer] ? CustomerSessionInput.new(attributes[:customer]) : nil
            if attributes[:purchase_units]
                @purchase_units = attributes[:purchase_units].map do |unit|
            PayPalPurchaseUnitInput.new(unit)
                end
      end
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
            variables["purchaseUnits"] = purchase_units.map(&:to_graphql_variables) if purchase_units
            variables
        end
    end
end


