module Braintree
  class Transaction
    class IdealPaymentDetails # :nodoc:
      include BaseModule

      attr_reader :bic
      attr_reader :ideal_payment_id
      attr_reader :ideal_transaction_id
      attr_reader :image_url
      attr_reader :masked_iban

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
