module Braintree
  class Transaction
    class SepaDirectDebitAccountDetails
      include BaseModule

      attr_reader :bank_reference_token
      attr_reader :capture_id
      attr_reader :debug_id
      attr_reader :global_id
      attr_reader :last_4
      attr_reader :mandate_type
      attr_reader :merchant_or_partner_customer_id
      attr_reader :paypal_v2_order_id
      attr_reader :refund_from_transaction_fee_amount
      attr_reader :refund_from_transaction_fee_currency_iso_code
      attr_reader :refund_id
      attr_reader :settlement_type
      attr_reader :token
      attr_reader :transaction_fee_amount
      attr_reader :transaction_fee_currency_iso_code

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
