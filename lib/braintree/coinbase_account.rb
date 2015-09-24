module Braintree
  class CoinbaseAccount
    include BaseModule # :nodoc:

    attr_reader :token, :user_id, :user_email, :user_name, :subscriptions, :created_at, :updated_at, :default, :customer_id
    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @subscriptions = (@subscriptions || []).map { |subscription_hash| Subscription._new(@gateway, subscription_hash) }
    end

    class << self
      protected :new
    end

    def self._new(*args) # :nodoc:
      self.new *args
    end

    # Returns true if this coinbase account is the customer's default payment method.
    def default?
      @default
    end
  end
end
