module Braintree
  # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/overview
  class Transaction
    include BaseModule

    module CreatedUsing
      FullInformation = 'full_information'
      Token = 'token'
    end

    module GatewayRejectionReason
      AVS = "avs"
      AVSAndCVV = "avs_and_cvv"
      CVV = "cvv"
      Duplicate = "duplicate"
    end

    module Status
      Authorizing = 'authorizing'
      Authorized = 'authorized'
      GatewayRejected = 'gateway_rejected'
      Failed = 'failed'
      ProcessorDeclined = 'processor_declined'
      Settled = 'settled'
      SettlementFailed = 'settlement_failed'
      SubmittedForSettlement = 'submitted_for_settlement'
      Voided = 'voided'

      All = constants.map { |c| const_get(c) }
    end

    module Source
      Api = "api"
      ControlPanel = "control_panel"
      Recurring = "recurring"
    end

    module Type # :nodoc:
      Credit = "credit" # :nodoc:
      Sale = "sale" # :nodoc:
    end

    attr_reader :avs_error_response_code, :avs_postal_code_response_code, :avs_street_address_response_code
    attr_reader :amount, :created_at, :credit_card_details, :customer_details, :id
    attr_reader :currency_iso_code
    attr_reader :custom_fields
    attr_reader :cvv_response_code
    attr_reader :gateway_rejection_reason
    attr_reader :merchant_account_id
    attr_reader :order_id
    attr_reader :billing_details, :shipping_details
    # The authorization code from the processor.
    attr_reader :processor_authorization_code
    # The response code from the processor.
    attr_reader :processor_response_code
    # The response text from the processor.
    attr_reader :processor_response_text
    attr_reader :refund_id, :refunded_transaction_id
    attr_reader :settlement_batch_id
    # See Transaction::Status
    attr_reader :status
    attr_reader :status_history
    attr_reader :subscription_id
    # Will either be "sale" or "credit"
    attr_reader :type
    attr_reader :updated_at
    attr_reader :add_ons, :discounts

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create
    def self.create(attributes)
      Configuration.gateway.transaction.create(attributes)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create
    def self.create!(attributes)
      return_object_or_raise(:transaction) { create(attributes) }
    end

    # Deprecated. Use Braintree::TransparentRedirect.confirm
    #
    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_tr
    def self.create_from_transparent_redirect(query_string)
      warn "[DEPRECATED] Transaction.create_from_transparent_redirect is deprecated. Please use TransparentRedirect.confirm"
      Configuration.gateway.transaction.create_from_transparent_redirect(query_string)
    end

    # Deprecated. Use Braintree::TransparentRedirect.url
    #
    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_tr
    def self.create_transaction_url
      warn "[DEPRECATED] Transaction.create_transaction_url is deprecated. Please use TransparentRedirect.url"
      Configuration.gateway.transaction.create_transaction_url
    end

    def self.credit(attributes)
      Configuration.gateway.transaction.credit(attributes)
    end

    def self.credit!(attributes)
      return_object_or_raise(:transaction) { credit(attributes) }
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/search
    def self.find(id)
      Configuration.gateway.transaction.find(id)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/refund
    def self.refund(id, amount = nil)
      Configuration.gateway.transaction.refund(id, amount)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create
    def self.sale(attributes)
      Configuration.gateway.transaction.sale(attributes)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create
    def self.sale!(attributes)
      return_object_or_raise(:transaction) { sale(attributes) }
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/search
    def self.search(&block)
      Configuration.gateway.transaction.search(&block)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/submit_for_settlement
    def self.submit_for_settlement(transaction_id, amount = nil)
      Configuration.gateway.transaction.submit_for_settlement(transaction_id, amount)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/submit_for_settlement
    def self.submit_for_settlement!(transaction_id, amount = nil)
      return_object_or_raise(:transaction) { submit_for_settlement(transaction_id, amount) }
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/void
    def self.void(transaction_id)
      Configuration.gateway.transaction.void(transaction_id)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/void
    def self.void!(transaction_id)
      return_object_or_raise(:transaction) { void(transaction_id) }
    end

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @amount = Util.to_big_decimal(amount)
      @credit_card_details = CreditCardDetails.new(@credit_card)
      @customer_details = CustomerDetails.new(@customer)
      @billing_details = AddressDetails.new(@billing)
      @shipping_details = AddressDetails.new(@shipping)
      @status_history = attributes[:status_history] ? attributes[:status_history].map { |s| StatusDetails.new(s) } : []
      add_ons.map! { |attrs| AddOn._new(attrs) } if add_ons
      discounts.map! { |attrs| Discount._new(attrs) } if discounts
    end

    # True if <tt>other</tt> is a Braintree::Transaction with the same id.
    def ==(other)
      return false unless other.is_a?(Transaction)
      id == other.id
    end

    def inspect # :nodoc:
      first = [:id, :type, :amount, :status]
      order = first + (self.class._attributes - first)
      nice_attributes = order.map do |attr|
        if attr == :amount
          self.amount ? "amount: #{self.amount.to_s("F").inspect}" : "amount: nil"
        else
          "#{attr}: #{send(attr).inspect}"
        end
      end
      "#<#{self.class} #{nice_attributes.join(', ')}>"
    end

    # Deprecated. Use Braintree::Transaction.refund
    #
    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/refund
    def refund(amount = nil)
      warn "[DEPRECATED] refund as an instance method is deprecated. Please use CreditCard.refund"
      result = @gateway.transaction.refund(id, amount)

      if result.success?
        SuccessfulResult.new(:new_transaction => result.transaction)
      else
        result
      end
    end

    # Returns true if the transaction has been refunded. False otherwise.
    def refunded?
      !@refund_id.nil?
    end

    # Deprecated. Use Braintree::Transaction.submit_for_settlement
    #
    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/submit_for_settlement
    def submit_for_settlement(amount = nil)
      warn "[DEPRECATED] submit_for_settlement as an instance method is deprecated. Please use CreditCard.submit_for_settlement"
      result = @gateway.transaction.submit_for_settlement(id, amount)
      if result.success?
        copy_instance_variables_from_object result.transaction
      end
      result
    end

    # Deprecated. Use Braintree::Transaction.submit_for_settlement!
    #
    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/submit_for_settlement
    def submit_for_settlement!(amount = nil)
      warn "[DEPRECATED] submit_for_settlement! as an instance method is deprecated. Please use CreditCard.submit_for_settlement!"
      return_object_or_raise(:transaction) { submit_for_settlement(amount) }
    end

    # If this transaction was stored in the vault, or created from vault records,
    # vault_billing_address will return the associated Braintree::Address. Because the
    # vault billing address can be updated after the transaction was created, the attributes
    # on vault_billing_address may not match the attributes on billing_details.
    def vault_billing_address
      return nil if billing_details.id.nil?
      @gateway.address.find(customer_details.id, billing_details.id)
    end

    # If this transaction was stored in the vault, or created from vault records,
    # vault_credit_card will return the associated Braintree::CreditCard. Because the
    # vault credit card can be updated after the transaction was created, the attributes
    # on vault_credit_card may not match the attributes on credit_card_details.
    def vault_credit_card
      return nil if credit_card_details.token.nil?
      @gateway.credit_card.find(credit_card_details.token)
    end

    # If this transaction was stored in the vault, or created from vault records,
    # vault_customer will return the associated Braintree::Customer. Because the
    # vault customer can be updated after the transaction was created, the attributes
    # on vault_customer may not match the attributes on customer_details.
    def vault_customer
      return nil if customer_details.id.nil?
      @gateway.customer.find(customer_details.id)
    end

    # If this transaction was stored in the vault, or created from vault records,
    # vault_shipping_address will return the associated Braintree::Address. Because the
    # vault shipping address can be updated after the transaction was created, the attributes
    # on vault_shipping_address may not match the attributes on shipping_details.
    def vault_shipping_address
      return nil if shipping_details.id.nil?
      @gateway.address.find(customer_details.id, shipping_details.id)
    end

    # Deprecated. Use Braintree::Transaction.void
    #
    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/void
    def void
      warn "[DEPRECATED] void as an instance method is deprecated. Please use CreditCard.void"
      result = @gateway.transaction.void(id)
      if result.success?
        copy_instance_variables_from_object result.transaction
      end
      result
    end

    # Deprecated. Use Braintree::Transaction.void!
    #
    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/void
    def void!
      warn "[DEPRECATED] void! as an instance method is deprecated. Please use CreditCard.void!"
      return_object_or_raise(:transaction) { void }
    end

    class << self
      protected :new
      def _new(*args) # :nodoc:
        self.new *args
      end
    end

    def self._attributes # :nodoc:
      [:amount, :created_at, :credit_card_details, :customer_details, :id, :status, :type, :updated_at]
    end
  end
end
