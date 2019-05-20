module Braintree
  class Transaction
    class LocalPaymentDetails
      include BaseModule

      attr_reader :custom_field
      attr_reader :description
      attr_reader :funding_source
      attr_reader :payer_id
      attr_reader :payment_id

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
