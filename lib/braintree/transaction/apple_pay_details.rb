module Braintree
  class Transaction
    class ApplePayDetails
      include BaseModule

      attr_reader :card_type
      attr_reader :cardholder_name
      attr_reader :expiration_month
      attr_reader :expiration_year
      attr_reader :last_4
      attr_reader :payment_instrument_name
      attr_reader :source_description

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
