module Braintree
  class Transaction
    class AddressDetails # :nodoc:
      include BaseModule

      attr_reader :id, :first_name, :last_name, :company,
        :street_address, :extended_address, :locality, :region,
        :postal_code, :country_code_alpha2, :country_code_alpha3,
        :country_code_numeric, :country_name

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
