module Braintree
  class Transaction
    class AmexExpressCheckoutDetails
      include BaseModule

      attr_reader :card_type, :token, :bin, :expiration_month, :expiration_year,
        :card_member_number, :card_member_expiry_date, :image_url, :source_description

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
