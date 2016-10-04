module Braintree
  class Transaction
    class UsBankAccountDetails # :nodoc:
      include BaseModule

      attr_reader :routing_number, :last_4, :account_type, :account_description, :account_holder_name, :token, :image_url

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
