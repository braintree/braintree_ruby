module Braintree
  class Transaction
    class IdealPaymentDetails # :nodoc:
      include BaseModule

      attr_reader :ideal_payment_id, :masked_iban, :bic, :image_url

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
