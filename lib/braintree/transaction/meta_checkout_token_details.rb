module Braintree
    class Transaction
      class MetaCheckoutTokenDetails # :nodoc:
        include BaseModule

        attr_reader :bin
        attr_reader :business
        attr_reader :card_type
        attr_reader :cardholder_name
        attr_reader :commercial
        attr_reader :consumer
        attr_reader :container_id
        attr_reader :corporate
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
        attr_reader :prepaid_reloadable
        attr_reader :product_id
        attr_reader :purchase
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
          attr_order = [
            :bin, :business, :card_type, :cardholder_name, :commercial, :consumer, :container_id,
            :corporate, :country_of_issuance, :cryptogram, :customer_location, :debit,
            :durbin_regulated, :ecommerce_indicator, :expiration_date, :healthcare, :image_url,
            :is_network_tokenized, :issuing_bank, :last_4, :payroll, :prepaid, :prepaid_reloadable,
            :product_id, :purchase, :token
          ]
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
