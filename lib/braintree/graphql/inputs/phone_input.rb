# Phone number input for PayPal customer session.

module Braintree
    class PhoneInput
        include BaseModule

        attr_reader :attrs
        attr_reader :country_phone_code
        attr_reader :phone_number
        attr_reader :extension_number

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
            variables["countryPhoneCode"] = country_phone_code if country_phone_code
            variables["phoneNumber"] = phone_number if phone_number
            variables["extensionNumber"] = extension_number if extension_number
            variables
        end
    end
end


