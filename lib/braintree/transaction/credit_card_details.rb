module Braintree
  class Transaction
    class CreditCardDetails # :nodoc:
      include BaseModule
      
      attr_reader :bin, :card_type, :expiration_month,
        :expiration_year, :issuer_location, :last_4, :token

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
      
      def expiration_date
        "#{expiration_month}/#{expiration_year}"
      end

      def masked_number
        "#{bin}******#{last_4}"
      end
    end
  end
end
