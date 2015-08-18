module Braintree
  class Transaction
    class AndroidPayDetails
      include BaseModule

      attr_reader :card_type, :last_4, :expiration_month, :expiration_year,
        :google_transaction_id, :virtual_card_type, :virtual_card_last_4,
        :source_card_type, :source_card_last_4, :source_description

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
        @card_type = @virtual_card_type
        @last_4 = @virtual_card_last_4
      end
    end
  end
end
