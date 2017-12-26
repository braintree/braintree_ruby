module Braintree
  class Dispute
    class Transaction # :nodoc:
      include BaseModule

      attr_reader :amount, :id, :order_id, :purchase_order_number, :payment_instrument_subtype

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
        @amount = Util.to_big_decimal(amount)
      end
    end
  end
end
