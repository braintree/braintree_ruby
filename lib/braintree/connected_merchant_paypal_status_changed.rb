module Braintree
  class ConnectedMerchantPayPalStatusChanged
    include BaseModule

    attr_reader :merchant_public_id, :action, :oauth_application_client_id

    def initialize(attributes)
      set_instance_variables_from_hash(attributes)
    end

    class << self
      protected :new
      def _new(*args) # :nodoc:
        self.new *args
      end
    end
  end
end
