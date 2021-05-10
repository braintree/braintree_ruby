module Braintree
  class Dispute
    class PayPalMessage # :nodoc:
      include BaseModule

      attr_reader :message,
        :sender,
        :sent_at

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
