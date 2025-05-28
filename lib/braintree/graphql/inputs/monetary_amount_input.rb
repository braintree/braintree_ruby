#Experimental
# This class is experimental and may change in future releases.
module Braintree
    class MonetaryAmountInput
        include BaseModule

        attr_reader :attrs
        attr_reader :value
        attr_reader :currency_code

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
            variables["value"] = value if value
            variables["currencyCode"] = currency_code if currency_code
            variables
        end
    end
end