module Braintree
  class Transaction
    class CreditCardDetails
      include BaseModule

      attr_reader :account_type
      attr_reader :bin
      attr_reader :card_type
      attr_reader :cardholder_name
      attr_reader :commercial
      attr_reader :country_of_issuance
      attr_reader :customer_location
      attr_reader :debit
      attr_reader :durbin_regulated
      attr_reader :expiration_month
      attr_reader :expiration_year
      attr_reader :healthcare
      attr_reader :image_url
      attr_reader :issuing_bank
      attr_reader :last_4
      attr_reader :payroll
      attr_reader :prepaid
      attr_reader :prepaid_reloadable
      attr_reader :product_id
      attr_reader :token
      attr_reader :unique_number_identifier

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end

      def expiration_date
        "#{expiration_month}/#{expiration_year}"
      end

      def inspect
        attr_order = [
          :bin,
          :card_type,
          :cardholder_name,
          :commercial,
          :country_of_issuance,
          :customer_location,
          :debit,
          :durbin_regulated,
          :expiration_date,
          :healthcare,
          :image_url,
          :issuing_bank,
          :last_4,
          :payroll,
          :prepaid,
          :prepaid_reloadable,
          :product_id,
          :token,
          :unique_number_identifier,
        ]

        formatted_attrs = attr_order.map do |attr|
          "#{attr}: #{send(attr).inspect}"
        end
        "#<#{formatted_attrs.join(", ")}>"
      end

      def masked_number
        "#{bin}******#{last_4}"
      end

      # NEXT_MAJOR_VERSION Remove this method
      # The old venmo SDK class has been deprecated
      def venmo_sdk?
        warn "[DEPRECATED] The Venmo SDK integration is Unsupported. Please update your integration to use Pay with Venmo instead."
        @venmo_sdk
      end

      def is_network_tokenized?
        @is_network_tokenized
      end
    end
  end
end
