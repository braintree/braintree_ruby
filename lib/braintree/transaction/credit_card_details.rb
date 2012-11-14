module Braintree
  class Transaction
    class CreditCardDetails # :nodoc:
      include BaseModule

      attr_reader :bin, :card_type, :cardholder_name, :customer_location, :expiration_month,
        :expiration_year, :last_4, :token, :prepaid, :healthcare, :durbin_regulated, :debit,
        :commercial, :payroll, :country_of_issuance, :issuing_bank

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end

      def expiration_date
        "#{expiration_month}/#{expiration_year}"
      end

      def inspect
        attr_order = [:token, :bin, :last_4, :card_type, :expiration_date, :cardholder_name, :customer_location, :prepaid,
        :healthcare, :durbin_regulated, :debit, :commercial, :payroll, :country_of_issuance, :issuing_bank]
        formatted_attrs = attr_order.map do |attr|
          "#{attr}: #{send(attr).inspect}"
        end
        "#<#{formatted_attrs.join(", ")}>"
      end

      def masked_number
        "#{bin}******#{last_4}"
      end
    end
  end
end
