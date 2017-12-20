module Braintree
  class Customer
    include BaseModule

    attr_reader :addresses
    attr_reader :amex_express_checkout_cards
    attr_reader :android_pay_cards
    attr_reader :apple_pay_cards
    attr_reader :coinbase_accounts
    attr_reader :company
    attr_reader :created_at
    attr_reader :credit_cards
    attr_reader :custom_fields
    attr_reader :email
    attr_reader :fax
    attr_reader :first_name
    attr_reader :id
    attr_reader :last_name
    attr_reader :masterpass_cards
    attr_reader :paypal_accounts
    attr_reader :phone
    attr_reader :updated_at
    attr_reader :us_bank_accounts
    attr_reader :venmo_accounts
    attr_reader :visa_checkout_cards
    attr_reader :website

    def self.all
      Configuration.gateway.customer.all
    end

    def self.create(attributes = {})
      Configuration.gateway.customer.create(attributes)
    end

    def self.create!(attributes = {})
      return_object_or_raise(:customer) { create(attributes) }
    end

    # Deprecated. Use Braintree::TransparentRedirect.url
    def self.create_customer_url
      warn "[DEPRECATED] Customer.create_customer_url is deprecated. Please use TransparentRedirect.url"
      Configuration.gateway.customer.create_customer_url
    end

    # Deprecated. Use Braintree::TransparentRedirect.confirm
    def self.create_from_transparent_redirect(query_string)
      warn "[DEPRECATED] Customer.create_from_transparent_redirect is deprecated. Please use TransparentRedirect.confirm"
      Configuration.gateway.customer.create_from_transparent_redirect(query_string)
    end

    def self.credit(customer_id, transaction_attributes)
      Transaction.credit(transaction_attributes.merge(:customer_id => customer_id))
    end

    def self.credit!(customer_id, transaction_attributes)
       return_object_or_raise(:transaction){ credit(customer_id, transaction_attributes) }
    end

    def self.delete(customer_id)
      Configuration.gateway.customer.delete(customer_id)
    end

    def self.find(customer_id)
      Configuration.gateway.customer.find(customer_id)
    end

    def self.sale(customer_id, transaction_attributes)
      Transaction.sale(transaction_attributes.merge(:customer_id => customer_id))
    end

    def self.sale!(customer_id, transaction_attributes)
      return_object_or_raise(:transaction) { sale(customer_id, transaction_attributes) }
    end

    def self.search(&block)
      Configuration.gateway.customer.search(&block)
    end

    # Returns a ResourceCollection of transactions for the customer with the given +customer_id+.
    def self.transactions(customer_id, options = {})
      Configuration.gateway.customer.transactions(customer_id, options = {})
    end

    def self.update(customer_id, attributes)
      Configuration.gateway.customer.update(customer_id, attributes)
    end

    def self.update!(customer_id, attributes)
      return_object_or_raise(:customer) { update(customer_id, attributes) }
    end

    # Deprecated. Use Braintree::TransparentRedirect.url
    def self.update_customer_url
      warn "[DEPRECATED] Customer.update_customer_url is deprecated. Please use TransparentRedirect.url"
      Configuration.gateway.customer.update_customer_url
    end

    # Deprecated. Use Braintree::TransparentRedirect.confirm
    def self.update_from_transparent_redirect(query_string)
      warn "[DEPRECATED] Customer.update_from_transparent_redirect is deprecated. Please use TransparentRedirect.confirm"
      Configuration.gateway.customer.update_from_transparent_redirect(query_string)
    end

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @credit_cards = (@credit_cards || []).map { |pm| CreditCard._new gateway, pm }
      @paypal_accounts = (@paypal_accounts || []).map { |pm| PayPalAccount._new gateway, pm }
      @coinbase_accounts = (@coinbase_accounts || []).map { |pm| CoinbaseAccount._new gateway, pm }
      @apple_pay_cards = (@apple_pay_cards || []).map { |pm| ApplePayCard._new gateway, pm }
      @europe_bank_accounts = (@europe_bank_Accounts || []).map { |pm| EuropeBankAccount._new gateway, pm }
      @android_pay_cards = (@android_pay_cards || []).map { |pm| AndroidPayCard._new gateway, pm }
      @amex_express_checkout_cards = (@amex_express_checkout_cards || []).map { |pm| AmexExpressCheckoutCard._new gateway, pm }
      @venmo_accounts = (@venmo_accounts || []).map { |pm| VenmoAccount._new gateway, pm }
      @us_bank_accounts = (@us_bank_accounts || []).map { |pm| UsBankAccount._new gateway, pm }
      @visa_checkout_cards = (@visa_checkout_cards|| []).map { |pm| VisaCheckoutCard._new gateway, pm }
      @masterpass_cards = (@masterpass_cards|| []).map { |pm| MasterpassCard._new gateway, pm }
      @addresses = (@addresses || []).map { |addr| Address._new gateway, addr }
      @custom_fields = attributes[:custom_fields].is_a?(Hash) ? attributes[:custom_fields] : {}
    end

    def credit(transaction_attributes)
      @gateway.transaction.credit(transaction_attributes.merge(:customer_id => id))
    end

    def credit!(transaction_attributes)
      return_object_or_raise(:transaction) { credit(transaction_attributes) }
    end

    # Deprecated. Use Braintree::Customer.default_payment_method
    #
    # Returns the customer's default credit card.
    def default_credit_card
      warn "[DEPRECATED] Customer#default_credit_card is deprecated. Please use Customer#default_payment_method"
      @credit_cards.find { |credit_card| credit_card.default? }
    end

    # Returns the customer's default payment method.
    def default_payment_method
      payment_methods.find { |payment_instrument| payment_instrument.default? }
    end

    def delete
      @gateway.customer.delete(id)
    end

    # Returns the customer's payment methods
    def payment_methods
      @credit_cards +
        @paypal_accounts +
        @apple_pay_cards +
        @coinbase_accounts +
        @android_pay_cards +
        @amex_express_checkout_cards +
        @venmo_accounts +
        @us_bank_accounts +
        @visa_checkout_cards
    end

    def inspect # :nodoc:
      first = [:id]
      last = [:addresses, :credit_cards, :paypal_accounts]
      order = first + (self.class._attributes - first - last) + last
      nice_attributes = order.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<#{self.class} #{nice_attributes.join(', ')}>"
    end

    # Deprecated. Use Braintree::Customer.sale
    def sale(transaction_attributes)
      warn "[DEPRECATED] sale as an instance method is deprecated. Please use Customer.sale"
      @gateway.transaction.sale(transaction_attributes.merge(:customer_id => id))
    end

    # Deprecated. Use Braintree::Customer.sale!
    def sale!(transaction_attributes)
      warn "[DEPRECATED] sale! as an instance method is deprecated. Please use Customer.sale!"
      return_object_or_raise(:transaction) { sale(transaction_attributes) }
    end

    # Returns a ResourceCollection of transactions for the customer.
    def transactions(options = {})
      @gateway.customer.transactions(id, options)
    end

    # Deprecated. Use Braintree::Customer.update
    def update(attributes)
      warn "[DEPRECATED] update as an instance method is deprecated. Please use Customer.update"
      result = @gateway.customer.update(id, attributes)
      if result.success?
        copy_instance_variables_from_object result.customer
      end
      result
    end

    # Deprecated. Use Braintree::Customer.update!
    def update!(attributes)
      warn "[DEPRECATED] update! as an instance method is deprecated. Please use Customer.update!"
      return_object_or_raise(:customer) { update(attributes) }
    end

    # Returns true if +other+ is a Customer with the same id
    def ==(other)
      return false unless other.is_a?(Customer)
      id == other.id
    end

    class << self
      protected :new
    end

    def self._new(*args) # :nodoc:
      self.new *args
    end

    def self._attributes # :nodoc:
      [
        :addresses, :company, :credit_cards, :email, :fax, :first_name, :id, :last_name, :phone, :website,
        :created_at, :updated_at
      ]
    end

    def self._now_timestamp # :nodoc:
      Time.now.to_i
    end
  end
end
