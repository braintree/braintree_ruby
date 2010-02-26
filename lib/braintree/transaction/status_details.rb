module Braintree
  class Transaction
    class StatusDetails # :nodoc:
      include BaseModule

      attr_reader :amount, :status, :timestamp, :transaction_source, :user

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
