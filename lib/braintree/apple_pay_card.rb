module Braintree
  # See https://developers.braintreepayments.com/ios+ruby/sdk/server
  class ApplePayCard
    include BaseModule # :nodoc:

    module CardType
      AmEx = "Apple Pay - American Express"
      Visa = "Apple Pay - Visa"
      MasterCard = "Apple Pay - MasterCard"

      All = constants.map { |c| const_get(c) }
    end

    attr_reader :token, :card_type, :last_4, :default, :image_url,
      :created_at, :updated_at, :subscriptions, :expiration_month,
      :expiration_year, :expired


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
  end
end
