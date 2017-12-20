module Braintree
  class Transaction
    class AddressDetails # :nodoc:
      include BaseModule

      attr_reader :company
      attr_reader :country_code_alpha2
      attr_reader :country_code_alpha3
      attr_reader :country_code_numeric
      attr_reader :country_name
      attr_reader :extended_address
      attr_reader :first_name
      attr_reader :id
      attr_reader :last_name
      attr_reader :locality
      attr_reader :postal_code
      attr_reader :region
      attr_reader :street_address

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
