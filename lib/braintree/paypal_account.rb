module Braintree
  class PayPalAccount
    include BaseModule

    attr_reader :email, :token, :image_url

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
    end

    class << self
      protected :new
    end

    def self._new(*args)
      self.new(*args)
    end

    def self.find(token)
      Configuration.gateway.paypal_account.find(token)
    end

    def self.update(token, attributes)
      Configuration.gateway.paypal_account.update(token, attributes)
    end

    def self.delete(token)
      Configuration.gateway.paypal_account.delete(token)
    end

    # See http://www.braintreepayments.com/docs/ruby/transactions/create_from_vault
    def self.sale(token, transaction_attributes)
      Configuration.gateway.transaction.sale(transaction_attributes.merge(:payment_method_token => token))
    end

    # See http://www.braintreepayments.com/docs/ruby/transactions/create_from_vault
    def self.sale!(token, transaction_attributes)
      return_object_or_raise(:transaction) { sale(token, transaction_attributes) }
    end

    # Returns true if this paypal account is the customer's default payment method.
    def default?
      @default
    end
  end
end
