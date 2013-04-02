module Braintree
  class Transaction
    class ServiceFeeDetails # :nodoc:
      include BaseModule

      attr_reader :merchant_account_id, :amount

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
        @amount = Util.to_big_decimal(amount)
      end
    end
  end
end
