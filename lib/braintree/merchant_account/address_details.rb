module Braintree
  class MerchantAccount
    class AddressDetails
      include BaseModule

      attr_reader :street_address, :locality, :region, :postal_code

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
