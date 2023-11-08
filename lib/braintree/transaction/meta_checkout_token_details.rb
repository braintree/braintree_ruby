module Braintree
    class Transaction
      class MetaCheckoutTokenDetails # :nodoc:
        include BaseModule

        attr_reader :bin
        attr_reader :container_id
        attr_reader :card_type
        attr_reader :cardholder_name
        attr_reader :commercial
        attr_reader :country_of_issuance
        attr_reader :created_at
        attr_reader :cryptogram
        attr_reader :customer_location
        attr_reader :debit
        attr_reader :durbin_regulated
        attr_reader :ecommerce_indicator
        attr_reader :expiration_month
        attr_reader :expiration_year
        attr_reader :healthcare
        attr_reader :image_url
        attr_reader :issuing_bank
        attr_reader :is_network_tokenized
        attr_reader :last_4
        attr_reader :payroll
        attr_reader :prepaid
        attr_reader :product_id
        attr_reader :token
        attr_reader :unique_number_identifier
        attr_reader :updated_at

        def initialize(attributes)
          set_instance_variables_from_hash attributes unless attributes.nil?
        end

        def expiration_date
          "#{expiration_month}/#{expiration_year}"
        end

        def inspect
          attr_order = [:container_id, :cryptogram, :ecommerce_indicator, :token, :bin, :last_4, :card_type, :expiration_date, :cardholder_name, :customer_location, :prepaid,
          :healthcare, :durbin_regulated, :debit, :commercial, :payroll, :product_id, :country_of_issuance, :issuing_bank, :is_network_tokenized, :image_url]
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
