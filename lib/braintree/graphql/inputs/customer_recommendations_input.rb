# Represents the input to request PayPal customer session recommendations.

module Braintree
    class CustomerRecommendationsInput
        include BaseModule

        attr_reader :attrs
        attr_reader :merchant_account_id
        attr_reader :session_id
        attr_reader :recommendations
        attr_reader :customer

        def initialize(attributes)
            unless attributes[:session_id]
                raise ArgumentError, "Expected hash to contain a :session_id"
            end
            unless attributes[:recommendations]
                raise ArgumentError, "Expected hash to contain a :recommendations"
            end
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
            variables["recommendations"] = recommendations if recommendations
            variables["customer"] = customer.to_graphql_variables if customer
            variables
        end
    end
end


