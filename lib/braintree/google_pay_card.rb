module Braintree
  class GooglePayCard
    include BaseModule

    attr_reader :bin
    attr_reader :business
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
    attr_reader :google_transaction_id
    attr_reader :healthcare
    attr_reader :image_url
    attr_reader :issuing_bank
    attr_reader :payroll
    attr_reader :prepaid
    attr_reader :prepaid_reloadable
    attr_reader :product_id
    attr_reader :purchase
    attr_reader :source_card_last_4
    attr_reader :source_card_type
    attr_reader :source_description
    attr_reader :subscriptions
    attr_reader :token
    attr_reader :updated_at
    attr_reader :virtual_card_last_4
    attr_reader :virtual_card_type

    def initialize(gateway, attributes)
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @subscriptions = (@subscriptions || []).map { |subscription_hash| Subscription._new(@gateway, subscription_hash) }
    end

    def default?
      @default
    end

    def is_network_tokenized?
      @is_network_tokenized
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

    def self._new(*args)
      self.new(*args)
    end
  end
end
