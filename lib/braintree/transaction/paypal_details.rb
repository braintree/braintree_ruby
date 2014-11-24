module Braintree
  class Transaction
    class PayPalDetails
      include BaseModule

      attr_reader :custom_field, :payer_email, :payment_id, :authorization_id, :token,
        :image_url, :debug_id, :payee_email

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
