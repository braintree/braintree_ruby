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

    attr_reader :bin, :card_type, :created_at, :default, :expiration_month,
      :expiration_year, :expired, :image_url, :last_4, :subscriptions,
      :token, :updated_at

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
