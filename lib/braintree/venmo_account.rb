module Braintree
  class VenmoAccount
    include BaseModule # :nodoc:

    attr_reader :customer_id, :username, :venmo_user_id, :token, :source_description, :subscriptions,
      :image_url, :default, :updated_at, :created_at

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @subscriptions = (@subscriptions || []).map { |subscription_hash| Subscription._new(@gateway, subscription_hash) }
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
  end
end

