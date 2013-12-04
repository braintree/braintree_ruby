module Braintree
  class MerchantAccount
    class IndividualDetails
      include BaseModule

      attr_reader :first_name, :last_name, :email, :phone, :date_of_birth, :ssn_last_4,
        :address_details

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
        @address_details = MerchantAccount::AddressDetails.new(@address)
      end
    end
  end
end
