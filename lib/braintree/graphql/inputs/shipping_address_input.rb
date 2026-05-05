module Braintree
  class ShippingAddressInput
    include BaseModule

    attr_reader :attrs
    attr_reader :country_code_alpha2
    attr_reader :extended_address
    attr_reader :locality
    attr_reader :postal_code
    attr_reader :region
    attr_reader :street_address

    def initialize(attributes)
      @attrs = attributes.keys
      set_instance_variables_from_hash(attributes)
    end

    def inspect
      inspected_attributes = @attrs.map { |attr| "#{attr}:#{send(attr).inspect}" }
      "#<#{self.class} #{inspected_attributes.join(" ")}>"
    end

    def to_graphql_variables
      {
        "countryCode" => country_code_alpha2,
        "extendedAddress" => extended_address,
        "locality" => locality,
        "postalCode" => postal_code,
        "region" => region,
        "streetAddress" => street_address
      }.compact
    end
  end
end
