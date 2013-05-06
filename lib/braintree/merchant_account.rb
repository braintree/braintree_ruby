module Braintree
  class MerchantAccount
    include BaseModule

    module Status
      Pending = "pending"
    end

    attr_reader :status

    def self.create(attributes)
      Configuration.gateway.merchant_account.create(attributes)
    end

    def initialize(gateway, attributes) # :nodoc
      @gateway = gateway
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
