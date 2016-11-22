module Braintree
  class UsBankAccount
    include BaseModule

    attr_reader :routing_number, :last_4, :account_type, :account_description, :account_holder_name, :token, :image_url, :bank_name, :ach_mandate, :default

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @ach_mandate = AchMandate.new(attributes[:ach_mandate]) if attributes[:ach_mandate]
    end

    def default?
      @default
    end

    class << self
      protected :new
    end

    def self._new(*args) # :nodoc:
      self.new *args
    end

    def self.find(token)
      Configuration.gateway.us_bank_account.find(token)
    end

    def self.sale(token, transaction_attributes)
      Configuration.gateway.transaction.sale(transaction_attributes.merge(
            :payment_method_token => token,
            :options => { :submit_for_settlement => true }
          )
        )
    end

    def self.sale!(token, transaction_attributes)
      return_object_or_raise(:transaction) { sale(token, transaction_attributes) }
    end
  end
end
