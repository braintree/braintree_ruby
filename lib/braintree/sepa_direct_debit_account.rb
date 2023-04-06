module Braintree
  class SepaDirectDebitAccount
    include BaseModule

    attr_reader :bank_reference_token
    attr_reader :created_at
    attr_reader :customer_id
    attr_reader :customer_global_id
    attr_reader :default
    attr_reader :global_id
    attr_reader :image_url
    attr_reader :last_4
    attr_reader :mandate_type
    attr_reader :merchant_or_partner_customer_id
    attr_reader :subscriptions
    attr_reader :token
    attr_reader :updated_at
    attr_reader :view_mandate_url

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      @subscriptions = (@subscriptions || []).map { |subscription_hash| Subscription._new(@gateway, subscription_hash) }
      set_instance_variables_from_hash(attributes)
    end

    def default?
      @default
    end

    class << self
      protected :new
    end

    def self._new(*args) # :nodoc:
      self.new(*args)
    end

    def self.find(*args)
      Configuration.gateway.sepa_direct_debit_account.find(*args)
    end

    def self.delete(*args)
      Configuration.gateway.sepa_direct_debit_account.delete(*args)
    end

    def self.sale(token, transaction_attributes)
      options = transaction_attributes[:options] || {}
      Configuration.gateway.transaction.sale(
        transaction_attributes.merge(
          :payment_method_token => token,
          :options => options.merge(:submit_for_settlement => true),
        ),
      )
    end

    def self.sale!(token, transaction_attributes)
      return_object_or_raise(:transaction) { sale(token, transaction_attributes) }
    end
  end
end
