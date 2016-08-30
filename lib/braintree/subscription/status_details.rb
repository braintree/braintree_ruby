module Braintree
  class Subscription
    class StatusDetails # :nodoc:
      include BaseModule

      attr_reader :balance, :price, :status, :subscription_source, :timestamp, :user, :currency_iso_code

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
