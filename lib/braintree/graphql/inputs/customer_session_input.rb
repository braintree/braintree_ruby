# Customer identifying information for a PayPal customer session.

#Experimental
# This class is experimental and may change in future releases.
module Braintree
    class CustomerSessionInput
        include BaseModule

        attr_reader :attrs
        attr_reader :email
        attr_reader :hashed_email
        attr_reader :phone
        attr_reader :hashed_phone
        attr_reader :device_fingerprint_id
        attr_reader :paypal_app_installed
        attr_reader :venmo_app_installed
        attr_reader :user_agent

        def initialize(attributes)
            @attrs = attributes.keys
            set_instance_variables_from_hash(attributes)
            @phone = attributes[:phone] ? PhoneInput.new(attributes[:phone]) : nil
        end

        def inspect
            inspected_attributes = @attrs.map { |attr| "#{attr}:#{send(attr).inspect}" }
            "#<#{self.class} #{inspected_attributes.join(" ")}>"
        end

        def to_graphql_variables
            variables = {}
            variables["email"] = email if email
            variables["hashedEmail"] = hashed_email if hashed_email
            variables["phone"] = phone.to_graphql_variables if phone
            variables["hashedPhone"] = hashed_phone if hashed_phone
            variables["deviceFingerprintId"] = device_fingerprint_id if device_fingerprint_id
            variables["paypalAppInstalled"] = paypal_app_installed if paypal_app_installed
            variables["venmoAppInstalled"] = venmo_app_installed if venmo_app_installed
            variables["userAgent"] = user_agent if user_agent
            variables
        end
    end
end


