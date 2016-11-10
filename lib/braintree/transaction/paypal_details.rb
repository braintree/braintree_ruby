module Braintree
  class Transaction
    class PayPalDetails
      include BaseModule

      attr_reader :custom_field, :payer_email, :payment_id, :authorization_id, :token,
        :image_url, :debug_id, :payee_email, :payer_id, :payer_first_name, :payer_last_name,
        :payer_status, :seller_protection_status, :capture_id, :refund_id, :transaction_fee_amount,
        :transaction_fee_currency_iso_code, :description

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
