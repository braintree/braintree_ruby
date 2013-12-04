module Braintree
  class MerchantAccount
    class BusinessDetails
      include BaseModule

      attr_reader :dba_name, :legal_name, :tax_id, :address_details

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
        @address_details = MerchantAccount::AddressDetails.new(@address)
      end
    end
  end
end
