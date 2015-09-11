module Braintree
  class AndroidPayCard
    include BaseModule # :nodoc:

    attr_reader :token, :virtual_card_type, :virtual_card_last_4, :source_card_type, :source_card_last_4,
      :expiration_month, :expiration_year, :created_at, :updated_at, :image_url, :subscriptions, :bin,
      :google_transaction_id, :default, :source_description, :customer_id

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @subscriptions = (@subscriptions || []).map { |subscription_hash| Subscription._new(@gateway, subscription_hash) }
    end

    def default?
      @default
    end

    def card_type
      virtual_card_type
    end

    def last_4
      virtual_card_last_4
    end

    class << self
      protected :new
    end

    def self._new(*args) # :nodoc:
      self.new *args
    end
  end
end
