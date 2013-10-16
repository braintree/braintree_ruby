module Braintree
  class MerchantAccount
    class BusinessDetails
      include BaseModule

      attr_reader :dba_name, :tax_id

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
