module Braintree
  class MerchantAccount
    class IndividualDetails
      include BaseModule

      attr_reader :first_name, :last_name, :email, :phone, :date_of_birth, :ssn,
        :address_details

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
        @address_details = AddressDetails.new(@address)
      end

      class AddressDetails
        include BaseModule

        attr_reader :street_address, :locality, :region, :postal_code

        def initialize(attributes)
          set_instance_variables_from_hash attributes unless attributes.nil?
        end
      end
    end
  end
end
