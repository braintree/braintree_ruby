module Braintree
  class PayerInfoInput
    include BaseModule

    attr_reader :attrs
    attr_reader :billing_address
    attr_reader :email
    attr_reader :given_name
    attr_reader :phone_country_code
    attr_reader :phone_number
    attr_reader :shipping_address
    attr_reader :surname

    def initialize(attributes)
      @attrs = attributes.keys
      set_instance_variables_from_hash(attributes)
      @billing_address = attributes[:billing_address] ? BillingAddressInput.new(attributes[:billing_address]) : nil
      @shipping_address = attributes[:shipping_address] ? ShippingAddressInput.new(attributes[:shipping_address]) : nil
    end

    def inspect
      inspected_attributes = @attrs.map { |attr| "#{attr}:#{send(attr).inspect}" }
      "#<#{self.class} #{inspected_attributes.join(" ")}>"
    end

    def to_graphql_variables
      {
        "billingAddress" => billing_address&.to_graphql_variables,
        "email" => email,
        "givenName" => given_name,
        "phoneCountryCode" => phone_country_code,
        "phoneNumber" => phone_number,
        "shippingAddress" => shipping_address&.to_graphql_variables,
        "surname" => surname
      }.compact
    end
  end
end
