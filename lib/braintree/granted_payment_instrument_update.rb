module Braintree
  class GrantedPaymentInstrumentUpdate
    include BaseModule

    attr_reader :grant_owner_merchant_id, :grant_recipient_merchant_id, :payment_method_nonce, :token, :updated_fields

    def initialize(attributes)
      set_instance_variables_from_hash(attributes)
      @payment_method_nonce = attributes[:payment_method_nonce][:nonce]
    end

    class << self
      protected :new
      def _new(*args) # :nodoc:
        self.new *args
      end
    end
  end
end
