module Braintree
  class ApplePayCard
    include BaseModule

    module CardType
      AmEx = "Apple Pay - American Express"
      Visa = "Apple Pay - Visa"
      MasterCard = "Apple Pay - MasterCard"

      All = constants.map { |c| const_get(c) }
    end

    attr_reader :billing_address
    attr_reader :bin
    attr_reader :business
    attr_reader :card_type
    attr_reader :cardholder_name
    attr_reader :commercial
    attr_reader :consumer
    attr_reader :corporate
    attr_reader :country_of_issuance
    attr_reader :created_at
    attr_reader :customer_id
    attr_reader :debit
    attr_reader :default
    attr_reader :durbin_regulated
    attr_reader :expiration_month
    attr_reader :expiration_year
    attr_reader :expired
    attr_reader :healthcare
    attr_reader :image_url
    attr_reader :is_device_token
    attr_reader :issuing_bank
    attr_reader :last_4
    attr_reader :merchant_token_identifier
    attr_reader :payment_instrument_name
    attr_reader :payroll
    attr_reader :prepaid
    attr_reader :prepaid_reloadable
    attr_reader :product_id
    attr_reader :purchase
    attr_reader :source_card_last4
    attr_reader :source_description
    attr_reader :subscriptions
    attr_reader :token
    attr_reader :updated_at

    def initialize(gateway, attributes)
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @billing_address = attributes[:billing_address] ? Address._new(@gateway, attributes[:billing_address]) : nil
      @subscriptions = (@subscriptions || []).map { |subscription_hash| Subscription._new(@gateway, subscription_hash) }
    end

    def default?
      @default
    end

    def expired?
      @expired
    end

    class << self
      protected :new
    end

    def self._new(*args)
      self.new(*args)
    end
  end
end
