module Braintree
  class Transaction
    class PayPalAccountDetails
      include BaseModule

      attr_reader :email, :token

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
