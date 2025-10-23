module Braintree
  class Transaction
    class ApplePayDetails
      include BaseModule

      attr_reader :bin
      attr_reader :business
      attr_reader :card_type
      attr_reader :cardholder_name
      attr_reader :commercial
      attr_reader :consumer
      attr_reader :corporate
      attr_reader :country_of_issuance
      attr_reader :debit
      attr_reader :durbin_regulated
      attr_reader :expiration_month
      attr_reader :expiration_year
      attr_reader :global_id
      attr_reader :healthcare
      attr_reader :image_url
      attr_reader :is_device_token
      attr_reader :issuing_bank
      attr_reader :last_4
      attr_reader :merchant_token_identifier
      attr_reader :payment_account_reference
      attr_reader :payment_instrument_name
      attr_reader :payroll
      attr_reader :prepaid
      attr_reader :prepaid_reloadable
      attr_reader :product_id
      attr_reader :purchase
      attr_reader :source_card_last4
      attr_reader :source_description
      attr_reader :token

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
