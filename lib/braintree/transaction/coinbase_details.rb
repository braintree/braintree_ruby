module Braintree
  class Transaction
    class CoinbaseDetails
      include BaseModule

      attr_reader :user_id, :user_name, :user_email, :token

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
