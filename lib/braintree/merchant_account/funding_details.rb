module Braintree
  class MerchantAccount
    class FundingDetails
      include BaseModule

      attr_reader :account_number_last_4, :routing_number

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
