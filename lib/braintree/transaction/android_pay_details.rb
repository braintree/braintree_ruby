module Braintree
  class Transaction
    class AndroidPayDetails
      include BaseModule

      attr_reader :card_type
      attr_reader :expiration_month
      attr_reader :expiration_year
      attr_reader :google_transaction_id
      attr_reader :last_4
      attr_reader :source_card_last_4
      attr_reader :source_card_type
      attr_reader :source_description
      attr_reader :virtual_card_last_4
      attr_reader :virtual_card_type

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
        @card_type = @virtual_card_type
        @last_4 = @virtual_card_last_4
      end
    end
  end
end
