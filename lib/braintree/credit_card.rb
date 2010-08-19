module Braintree
  # See http://www.braintreepaymentsolutions.com/docs/ruby
  class CreditCard
    include BaseModule # :nodoc:

    module CardType
      AmEx = "American Express"
      CarteBlanche = "Carte Blanche"
      ChinaUnionPay = "China UnionPay"
      DinersClubInternational = "Diners Club"
      Discover = "Discover"
      JCB = "JCB"
      Laser = "Laser"
      Maestro = "Maestro"
      MasterCard = "MasterCard"
      Solo = "Solo"
      Switch = "Switch"
      Visa = "Visa"
      Unknown = "Unknown"

      All = constants.map { |c| const_get(c) }
    end

    module CustomerLocation
      International = "international"
      US = "us"
    end

    attr_reader :billing_address, :bin, :card_type, :cardholder_name, :created_at, :customer_id, :expiration_month,
      :expiration_year, :last_4, :subscriptions, :token, :updated_at

    # See http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/create
    def self.create(attributes)
      Configuration.gateway.credit_card.create(attributes)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/create
    def self.create!(attributes)
      return_object_or_raise(:credit_card) { create(attributes) }
    end

    # Deprecated. Use Braintree::TransparentRedirect.url
    # See http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/create_tr
    def self.create_credit_card_url
      warn "[DEPRECATED] CreditCard.create_credit_card_url is deprecated. Please use TransparentRedirect.url"
      Configuration.gateway.credit_card.create_credit_card_url
    end

    # Deprecated. Use Braintree::TransparentRedirect.confirm
    # See http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/create_tr
    def self.create_from_transparent_redirect(query_string)
      warn "[DEPRECATED] CreditCard.create_from_transparent_redirect is deprecated. Please use TransparentRedirect.confirm"
      Configuration.gateway.credit_card.create_from_transparent_redirect(query_string)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_from_vault
    def self.credit(token, transaction_attributes)
      Transaction.credit(transaction_attributes.merge(:payment_method_token => token))
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_from_vault
    def self.credit!(token, transaction_attributes)
      return_object_or_raise(:transaction) { credit(token, transaction_attributes) }
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/delete
    def self.delete(token)
      Configuration.gateway.credit_card.delete(token)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/search
    def self.expired(options = {})
      Configuration.gateway.credit_card.expired(options)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/search
    def self.expiring_between(start_date, end_date, options = {})
      Configuration.gateway.credit_card.expiring_between(start_date, end_date, options)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/search
    def self.find(token)
      Configuration.gateway.credit_card.find(token)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_from_vault
    def self.sale(token, transaction_attributes)
      Configuration.gateway.transaction.sale(transaction_attributes.merge(:payment_method_token => token))
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_from_vault
    def self.sale!(token, transaction_attributes)
      return_object_or_raise(:transaction) { sale(token, transaction_attributes) }
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/update
    def self.update(token, attributes)
      Configuration.gateway.credit_card.update(token, attributes)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/update
    def self.update!(token, attributes)
      return_object_or_raise(:credit_card) { update(token, attributes) }
    end

    # Deprecated. Use Braintree::TransparentRedirect.confirm
    #
    # See http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/update_tr
    def self.update_from_transparent_redirect(query_string)
      warn "[DEPRECATED] CreditCard.update_via_transparent_redirect_request is deprecated. Please use TransparentRedirect.confirm"
      Configuration.gateway.credit_card.update_from_transparent_redirect(query_string)
    end

    # Deprecated. Use Braintree::TransparentRedirect.url
    #
    # See http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/update_tr
    def self.update_credit_card_url
      warn "[DEPRECATED] CreditCard.update_credit_card_url is deprecated. Please use TransparentRedirect.url"
      Configuration.gateway.credit_card.update_credit_card_url
    end

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @billing_address = attributes[:billing_address] ? Address._new(@gateway, attributes[:billing_address]) : nil
      @subscriptions = (@subscriptions || []).map { |subscription_hash| Subscription._new(@gateway, subscription_hash) }
    end

    # Deprecated. Use Braintree::CreditCard.credit
    #
    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_from_vault
    def credit(transaction_attributes)
      warn "[DEPRECATED] credit as an instance method is deprecated. Please use CreditCard.credit"
      @gateway.transaction.credit(transaction_attributes.merge(:payment_method_token => token))
    end

    # Deprecated. Use Braintree::CreditCard.credit!
    #
    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_from_vault
    def credit!(transaction_attributes)
      warn "[DEPRECATED] credit! as an instance method is deprecated. Please use CreditCard.credit!"
      return_object_or_raise(:transaction) { credit(transaction_attributes) }
    end

    # Deprecated. Use Braintree::CreditCard.delete
    #
    # http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/delete
    def delete
      warn "[DEPRECATED] delete as an instance method is deprecated. Please use CreditCard.delete"
      @gateway.credit_card.delete(token)
    end

    # Returns true if this credit card is the customer's default.
    def default?
      @default
    end

    # Expiration date formatted as MM/YYYY
    def expiration_date
      "#{expiration_month}/#{expiration_year}"
    end

    # Returns true if the credit card is expired.
    def expired?
      @expired
    end

    def inspect # :nodoc:
      first = [:token]
      order = first + (self.class._attributes - first)
      nice_attributes = order.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<#{self.class} #{nice_attributes.join(', ')}>"
    end

    def masked_number
      "#{bin}******#{last_4}"
    end

    # Deprecated. Use Braintree::CreditCard.sale
    #
    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_from_vault
    def sale(transaction_attributes)
      warn "[DEPRECATED] sale as an instance method is deprecated. Please use CreditCard.sale"
      @gateway.transaction.sale(transaction_attributes.merge(:payment_method_token => token))
    end

    # Deprecated. Use Braintree::CreditCard.sale!
    #
    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_from_vault
    def sale!(transaction_attributes)
      warn "[DEPRECATED] sale! as an instance method is deprecated. Please use CreditCard.sale!"
      return_object_or_raise(:transaction) { sale(transaction_attributes) }
    end

    # Deprecated. Use Braintree::CreditCard.update
    #
    # See http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/update
    def update(attributes)
      warn "[DEPRECATED] update as an instance method is deprecated. Please use CreditCard.update"
      result = @gateway.credit_card.update(token, attributes)
      if result.success?
        copy_instance_variables_from_object result.credit_card
      end
      result
    end

    # Deprecated. Use Braintree::CreditCard.update!
    #
    # See http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/update
    def update!(attributes)
      warn "[DEPRECATED] update! as an instance method is deprecated. Please use CreditCard.update!"
      return_object_or_raise(:credit_card) { update(attributes) }
    end

    # Returns true if +other+ is a +CreditCard+ with the same token.
    def ==(other)
      return false unless other.is_a?(CreditCard)
      token == other.token
    end

    class << self
      protected :new
    end

    def self._attributes # :nodoc:
      [
        :billing_address, :bin, :card_type, :cardholder_name, :created_at, :customer_id, :expiration_month,
        :expiration_year, :last_4, :token, :updated_at
      ]
    end

    def self._new(*args) # :nodoc:
      self.new *args
    end
  end
end
