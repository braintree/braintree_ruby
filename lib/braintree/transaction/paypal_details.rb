module Braintree
  class Transaction
    class PayPalDetails
      include BaseModule

      attr_reader :payer_email, :payer_first_name, :payer_last_name, :payment_id,
        :authorization_id, :token

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
