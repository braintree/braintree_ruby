module Braintree
  class MerchantAccount
    class FundingDetails
      include BaseModule

      attr_reader :account_number_last_4, :destination, :email, :mobile_phone, :routing_number, :descriptor

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
