module Braintree
  class Transaction
    class ApplePayDetails
      include BaseModule

      attr_reader :card_type, :last_4, :expiration_month, :expiration_year,
        :cardholder_name

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
