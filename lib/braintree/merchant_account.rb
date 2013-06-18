module Braintree
  class MerchantAccount
    include BaseModule

    module Status
      Pending = "pending"
      Active = "active"
      Suspended = "suspended"
    end

    attr_reader :status, :id, :master_merchant_account

    def self.create(attributes)
      Configuration.gateway.merchant_account.create(attributes)
    end

    def initialize(gateway, attributes) # :nodoc
      @gateway = gateway
      @master_merchant_account = MerchantAccount._new(@gateway, attributes.delete(:master_merchant_account)) if attributes[:master_merchant_account]
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
