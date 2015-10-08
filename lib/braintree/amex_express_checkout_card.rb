module Braintree
  class AmexExpressCheckoutCard
    include BaseModule # :nodoc:

    attr_reader :bin, :card_member_expiry_date, :card_member_number, :card_type, :created_at, :customer_id, :default,
      :expiration_month, :expiration_year, :image_url, :source_description, :subscriptions, :token, :updated_at

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
