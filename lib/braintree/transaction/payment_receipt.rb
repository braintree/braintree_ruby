module Braintree
  class Transaction
    class PaymentReceipt
      include BaseModule

      attr_reader :account_balance
      attr_reader :amount
      attr_reader :card_last_4
      attr_reader :card_present_data
      attr_reader :card_type
      attr_reader :currency_iso_code
      attr_reader :global_id
      attr_reader :id
      attr_reader :merchant_address
      attr_reader :merchant_identification_number
      attr_reader :merchant_name
      attr_reader :pin_verified
      attr_reader :processor_authorization_code
      attr_reader :processor_response_code
      attr_reader :processor_response_text
      attr_reader :terminal_identification_number
      attr_reader :type

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
        @card_present_data = CardPresentData.new(attributes[:card_present_date]) if attributes[:card_present_data]
        @merchant_address = MerchantAddress.new(attributes[:merchant_address]) if attributes[:merchant_address]
      end
    end
  end
end
