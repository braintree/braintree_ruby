module Braintree
  class Customer
    include BaseModule
    include Braintree::Util::IdEquality

    attr_reader :addresses
    attr_reader :apple_pay_cards
    attr_reader :company
    attr_reader :created_at
    attr_reader :credit_cards
    attr_reader :custom_fields
    attr_reader :email
    attr_reader :fax
    attr_reader :first_name
    attr_reader :google_pay_cards
    attr_reader :graphql_id
    attr_reader :id
    attr_reader :international_phone
    attr_reader :last_name
    attr_reader :paypal_accounts
    attr_reader :phone
    attr_reader :samsung_pay_cards
    attr_reader :sepa_direct_debit_accounts
    attr_reader :tax_identifiers
    attr_reader :updated_at
    attr_reader :us_bank_accounts
    attr_reader :venmo_accounts
    attr_reader :visa_checkout_cards
    attr_reader :website

    def self.all
      Configuration.gateway.customer.all
    end

    def self.create(*args)
      Configuration.gateway.customer.create(*args)
    end

    def self.create!(*args)
      Configuration.gateway.customer.create!(*args)
    end

    def self.credit(customer_id, transaction_attributes)
      Transaction.credit(transaction_attributes.merge(:customer_id => customer_id))
    end

    def self.credit!(customer_id, transaction_attributes)
       return_object_or_raise(:transaction) { credit(customer_id, transaction_attributes) }
    end

    def self.delete(*args)
      Configuration.gateway.customer.delete(*args)
    end

    def self.find(*args)
      Configuration.gateway.customer.find(*args)
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

    def self.transactions(*args)
      Configuration.gateway.customer.transactions(*args)
    end

    def self.update(*args)
      Configuration.gateway.customer.update(*args)
    end

    def self.update!(*args)
      Configuration.gateway.customer.update!(*args)
    end

    # NEXT_MAJOR_VERSION remove samsung_pay_cards
    def initialize(gateway, attributes)
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @credit_cards = (@credit_cards || []).map { |pm| CreditCard._new gateway, pm }
      @paypal_accounts = (@paypal_accounts || []).map { |pm| PayPalAccount._new gateway, pm }
      @apple_pay_cards = (@apple_pay_cards || []).map { |pm| ApplePayCard._new gateway, pm }
      @google_pay_cards = (@google_pay_cards || []).map { |pm| GooglePayCard._new gateway, pm }
      @venmo_accounts = (@venmo_accounts || []).map { |pm| VenmoAccount._new gateway, pm }
      @us_bank_accounts = (@us_bank_accounts || []).map { |pm| UsBankAccount._new gateway, pm }
      @visa_checkout_cards = (@visa_checkout_cards|| []).map { |pm| VisaCheckoutCard._new gateway, pm }
      @sepa_direct_debit_accounts = (@sepa_debit_accounts || []).map { |pm| SepaDirectDebitAccount._new gateway, pm }
      @samsung_pay_cards = (@samsung_pay_cards|| []).map { |pm| SamsungPayCard._new gateway, pm } # Deprecated
      @addresses = (@addresses || []).map { |addr| Address._new gateway, addr }
      @tax_identifiers = (@tax_identifiers || []).map { |addr| TaxIdentifier._new gateway, addr }
      @custom_fields = attributes[:custom_fields].is_a?(Hash) ? attributes[:custom_fields] : {}
    end

    def credit(transaction_attributes)
      @gateway.transaction.credit(transaction_attributes.merge(:customer_id => id))
    end

    def credit!(transaction_attributes)
      return_object_or_raise(:transaction) { credit(transaction_attributes) }
    end

    def default_payment_method
      payment_methods.find { |payment_instrument| payment_instrument.default? }
    end

    def delete
      @gateway.customer.delete(id)
    end

    def payment_methods
      @credit_cards +
        @paypal_accounts +
        @apple_pay_cards +
        @google_pay_cards +
        @venmo_accounts +
        @us_bank_accounts +
        @visa_checkout_cards +
        @samsung_pay_cards +
        @sepa_direct_debit_accounts
    end

    def inspect
      first = [:id]
      last = [:addresses, :credit_cards, :paypal_accounts, :tax_identifiers]
      order = first + (self.class._attributes - first - last) + last
      nice_attributes = order.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<#{self.class} #{nice_attributes.join(', ')}>"
    end

    def transactions(options = {})
      @gateway.customer.transactions(id, options)
    end

    class << self
      protected :new
    end

    def self._new(*args)
      self.new(*args)
    end

    def self._attributes
      [
        :addresses, :company, :credit_cards, :email, :fax, :first_name, :id, :international_phone,
        :last_name, :phone, :website, :created_at, :updated_at, :tax_identifiers
      ]
    end

    def self._now_timestamp
      Time.now.to_i
    end
  end
end
