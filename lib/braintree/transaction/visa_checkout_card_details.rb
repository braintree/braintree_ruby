module Braintree
  class Transaction
    class VisaCheckoutCardDetails # :nodoc:
      include BaseModule

      attr_reader :bin, :card_type, :cardholder_name, :commercial, :country_of_issuance,
        :customer_location, :debit, :durbin_regulated, :expiration_month, :expiration_year,
        :healthcare, :image_url, :issuing_bank, :last_4, :payroll, :prepaid, :product_id,
        :token, :call_id

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end

      def expiration_date
        "#{expiration_month}/#{expiration_year}"
      end

      def inspect
        attr_order = [:token, :bin, :last_4, :card_type, :expiration_date, :cardholder_name, :customer_location, :prepaid,
        :healthcare, :durbin_regulated, :debit, :commercial, :payroll, :product_id, :country_of_issuance, :issuing_bank, :image_url, :call_id]
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
