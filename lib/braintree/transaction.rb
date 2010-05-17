module Braintree
  # == Creating a Transaction
  #
  # At minimum, an amount, credit card number, and credit card expiration date are required. Minimalistic
  # example:
  #  Braintree::Transaction.sale!(
  #    :amount => "100.00",
  #    :credit_card => {
  #      :number => "5105105105105100",
  #      :expiration_date => "05/2012"
  #    }
  #  )
  #
  # Full example:
  #
  #  Braintree::Transaction.sale!(
  #    :amount => "100.00",
  #    :order_id => "123",
  #    :credit_card => {
  #      # if :token is omitted, the gateway will generate a token
  #      :token => "credit_card_123",
  #      :number => "5105105105105100",
  #      :expiration_date => "05/2011",
  #      :cvv => "123"
  #    },
  #    :customer => {
  #      # if :id is omitted, the gateway will generate an id
  #      :id => "customer_123",
  #      :first_name => "Dan",
  #      :last_name => "Smith",
  #      :company => "Braintree Payment Solutions",
  #      :email => "dan@example.com",
  #      :phone => "419-555-1234",
  #      :fax => "419-555-1235",
  #      :website => "http://braintreepaymentsolutions.com"
  #    },
  #    :billing => {
  #      :first_name => "Carl",
  #      :last_name => "Jones",
  #      :company => "Braintree",
  #      :street_address => "123 E Main St",
  #      :extended_address => "Suite 403",
  #      :locality => "Chicago",
  #      :region => "IL",
  #      :postal_code => "60622",
  #      :country_name => "United States of America"
  #    },
  #    :shipping => {
  #      :first_name => "Andrew",
  #      :last_name => "Mason",
  #      :company => "Braintree",
  #      :street_address => "456 W Main St",
  #      :extended_address => "Apt 2F",
  #      :locality => "Bartlett",
  #      :region => "IL",
  #      :postal_code => "60103",
  #      :country_name => "United States of America"
  #    },
  #    :custom_fields => {
  #      :birthdate => "11/13/1954"
  #    }
  #  )
  #
  # == Storing in the Vault
  #
  # The customer and credit card information used for
  # a transaction can be stored in the vault by setting
  # <tt>transaction[options][store_in_vault]</tt> to true.
  #
  #   transaction = Braintree::Transaction.sale!(
  #     :customer => {
  #       :first_name => "Adam",
  #       :last_name => "Williams"
  #     },
  #     :credit_card => {
  #       :number => "5105105105105100",
  #       :expiration_date => "05/2012"
  #     },
  #     :options => {
  #       :store_in_vault => true
  #     }
  #   )
  #   transaction.customer_details.id
  #   # => "865534"
  #   transaction.credit_card_details.token
  #   # => "6b6m"
  #
  # To also store the billing address in the vault, pass the
  # +add_billing_address_to_payment_method+ option.
  #
  #   Braintree::Transaction.sale!(
  #     # ...
  #     :options => {
  #       :store_in_vault => true
  #       :add_billing_address_to_payment_method => true
  #     }
  #   )
  #
  # == Submitting for Settlement
  #
  # This can only be done when the transction's
  # status is +authorized+. If +amount+ is not specified, the full authorized amount will be
  # settled. If you would like to settle less than the full authorized amount, pass the
  # desired amount. You cannot settle more than the authorized amount.
  #
  # A transaction can be submitted for settlement when created by setting
  # transaction[options][submit_for_settlement] to true.
  #
  #   transaction = Braintree::Transaction.sale!(
  #     :amount => "100.00",
  #     :credit_card => {
  #       :number => "5105105105105100",
  #       :expiration_date => "05/2012"
  #     },
  #     :options => {
  #       :submit_for_settlement => true
  #     }
  #   )
  #
  # == More Information
  #
  # For more detailed documentation on Transactions, see http://www.braintreepaymentsolutions.com/gateway/transaction-api
  class Transaction
    include BaseModule

    module CreatedUsing
      FullInformation = 'full_information'
      Token = 'token'
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
      Unknown = 'unknown'
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
    attr_reader :custom_fields
    attr_reader :cvv_response_code
    attr_reader :merchant_account_id
    attr_reader :order_id
    attr_reader :billing_details, :shipping_details
    # The authorization code from the processor.
    attr_reader :processor_authorization_code
    # The response code from the processor.
    attr_reader :processor_response_code
    # The response text from the processor.
    attr_reader :processor_response_text
    # See Transaction::Status
    attr_reader :status
    attr_reader :status_history
    # Will either be "sale" or "credit"
    attr_reader :type
    attr_reader :updated_at

    def self.create(attributes)
      Util.verify_keys(_create_signature, attributes)
      _do_create "/transactions", :transaction => attributes
    end

    def self.create!(attributes)
      return_object_or_raise(:transaction) { create(attributes) }
    end

    def self.create_from_transparent_redirect(query_string)
      params = TransparentRedirect.parse_and_validate_query_string query_string
      _do_create("/transactions/all/confirm_transparent_redirect_request", :id => params[:id])
    end

    # The URL to use to create transactions via transparent redirect.
    def self.create_transaction_url
      "#{Braintree::Configuration.base_merchant_url}/transactions/all/create_via_transparent_redirect_request"
    end

    # Creates a credit transaction.
    def self.credit(attributes)
      create(attributes.merge(:type => 'credit'))
    end

    def self.credit!(attributes)
      return_object_or_raise(:transaction) { credit(attributes) }
    end

    # Finds the transaction with the given id. Raises a Braintree::NotFoundError
    # if the transaction cannot be found.
    def self.find(id)
      response = Http.get "/transactions/#{id}"
      new(response[:transaction])
    rescue NotFoundError
      raise NotFoundError, "transaction with id #{id.inspect} not found"
    end

    # Creates a sale transaction.
    def self.sale(attributes)
      create(attributes.merge(:type => 'sale'))
    end

    def self.sale!(attributes)
      return_object_or_raise(:transaction) { sale(attributes) }
    end

    # Returns a ResourceCollection of transactions matching the search query.
    # If <tt>query</tt> is a string, the search will be a basic search.
    # If <tt>query</tt> is a hash, the search will be an advanced search.
    # See: http://www.braintreepaymentsolutions.com/gateway/transaction-api#searching
    def self.search(&block)
      search = TransactionSearch.new
      block.call(search) if block

      response = Http.post "/transactions/advanced_search_ids", {:search => search.to_hash}
      ResourceCollection.new(response) { |ids| _fetch_transactions(search, ids) }
    end

    # Submits transaction with +transaction_id+ for settlement.
    def self.submit_for_settlement(transaction_id, amount = nil)
      raise ArgumentError, "transaction_id is invalid" unless transaction_id =~ /\A[0-9a-z]+\z/
      response = Http.put "/transactions/#{transaction_id}/submit_for_settlement", :transaction => {:amount => amount}
      if response[:transaction]
        SuccessfulResult.new(:transaction => new(response[:transaction]))
      elsif response[:api_error_response]
        ErrorResult.new(response[:api_error_response])
      else
        raise UnexpectedError, "expected :transaction or :response"
      end
    end

    def self.submit_for_settlement!(transaction_id, amount = nil)
      return_object_or_raise(:transaction) { submit_for_settlement(transaction_id, amount) }
    end

    # Voids the transaction with the given <tt>transaction_id</tt>
    def self.void(transaction_id)
      response = Http.put "/transactions/#{transaction_id}/void"
      if response[:transaction]
        SuccessfulResult.new(:transaction => new(response[:transaction]))
      elsif response[:api_error_response]
        ErrorResult.new(response[:api_error_response])
      else
        raise UnexpectedError, "expected :transaction or :api_error_response"
      end
    end

    def self.void!(transaction_id)
      return_object_or_raise(:transaction) { void(transaction_id) }
    end

    def initialize(attributes) # :nodoc:
      _init attributes
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

    # Creates a credit transaction that refunds this transaction.
    def refund(amount = nil)
      response = Http.post "/transactions/#{id}/refund", :transaction => {:amount => amount}
      if response[:transaction]
        # TODO: need response to return original_transaction so that we can update status, updated_at, etc.
        SuccessfulResult.new(:new_transaction => Transaction._new(response[:transaction]))
      elsif response[:api_error_response]
        ErrorResult.new(response[:api_error_response])
      else
        raise UnexpectedError, "expected :transaction or :api_error_response"
      end
    end

    # Returns true if the transaction has been refunded. False otherwise.
    def refunded?
      !@refund_id.nil?
    end

    # Submits the transaction for settlement.
    def submit_for_settlement(amount = nil)
      response = Http.put "/transactions/#{id}/submit_for_settlement", :transaction => {:amount => amount}
      if response[:transaction]
        _init(response[:transaction])
        SuccessfulResult.new :transaction => self
      elsif response[:api_error_response]
        ErrorResult.new(response[:api_error_response])
      else
        raise UnexpectedError, "expected transaction or api_error_response"
      end
    end

    def submit_for_settlement!(amount = nil)
      return_object_or_raise(:transaction) { submit_for_settlement(amount) }
    end

    # If this transaction was stored in the vault, or created from vault records,
    # vault_billing_address will return the associated Braintree::Address. Because the
    # vault billing address can be updated after the transaction was created, the attributes
    # on vault_billing_address may not match the attributes on billing_details.
    def vault_billing_address
      return nil if billing_details.id.nil?
      Address.find(customer_details.id, billing_details.id)
    end

    # If this transaction was stored in the vault, or created from vault records,
    # vault_credit_card will return the associated Braintree::CreditCard. Because the
    # vault credit card can be updated after the transaction was created, the attributes
    # on vault_credit_card may not match the attributes on credit_card_details.
    def vault_credit_card
      return nil if credit_card_details.token.nil?
      CreditCard.find(credit_card_details.token)
    end

    # If this transaction was stored in the vault, or created from vault records,
    # vault_customer will return the associated Braintree::Customer. Because the
    # vault customer can be updated after the transaction was created, the attributes
    # on vault_customer may not match the attributes on customer_details.
    def vault_customer
      return nil if customer_details.id.nil?
      Customer.find(customer_details.id)
    end

    # If this transaction was stored in the vault, or created from vault records,
    # vault_shipping_address will return the associated Braintree::Address. Because the
    # vault shipping address can be updated after the transaction was created, the attributes
    # on vault_shipping_address may not match the attributes on shipping_details.
    def vault_shipping_address
      return nil if shipping_details.id.nil?
      Address.find(customer_details.id, shipping_details.id)
    end

    # Voids the transaction.
    def void
      response = Http.put "/transactions/#{id}/void"
      if response[:transaction]
        _init response[:transaction]
        SuccessfulResult.new(:transaction => self)
      elsif response[:api_error_response]
        ErrorResult.new(response[:api_error_response])
      else
        raise UnexpectedError, "expected :transaction or :api_error_response"
      end
    end

    def void!
      return_object_or_raise(:transaction) { void }
    end

    class << self
      protected :new
      def _new(*args) # :nodoc:
        self.new *args
      end
    end

    def self._do_create(url, params) # :nodoc:
      response = Http.post url, params
      if response[:transaction]
        SuccessfulResult.new(:transaction => new(response[:transaction]))
      elsif response[:api_error_response]
        ErrorResult.new(response[:api_error_response])
      else
        raise UnexpectedError, "expected :transaction or :api_error_response"
      end
    end

    def self._attributes # :nodoc:
      [:amount, :created_at, :credit_card_details, :customer_details, :id, :status, :type, :updated_at]
    end

    def self._create_signature # :nodoc:
      [
        :amount, :customer_id, :merchant_account_id, :order_id, :payment_method_token, :type,
        {:credit_card => [:token, :cardholder_name, :cvv, :expiration_date, :expiration_month, :expiration_year, :number]},
        {:customer => [:id, :company, :email, :fax, :first_name, :last_name, :phone, :website]},
        {:billing => [:first_name, :last_name, :company, :country_name, :extended_address, :locality, :postal_code, :region, :street_address]},
        {:shipping => [:first_name, :last_name, :company, :country_name, :extended_address, :locality, :postal_code, :region, :street_address]},
        {:options => [:store_in_vault, :submit_for_settlement, :add_billing_address_to_payment_method, :store_shipping_address_in_vault]},
        {:custom_fields => :_any_key_}
      ]
    end

    def self._fetch_transactions(search, ids)
      search.ids.in ids
      response = Http.post "/transactions/advanced_search", {:search => search.to_hash}
      attributes = response[:credit_card_transactions]
      Util.extract_attribute_as_array(attributes, :transaction).map { |attrs| _new(attrs) }
    end

    def _init(attributes) # :nodoc:
      set_instance_variables_from_hash(attributes)
      @amount = Util.to_big_decimal(amount)
      @credit_card_details = CreditCardDetails.new(@credit_card)
      @customer_details = CustomerDetails.new(@customer)
      @billing_details = AddressDetails.new(@billing)
      @shipping_details = AddressDetails.new(@shipping)
      @status_history = attributes[:status_history] ? attributes[:status_history].map { |s| StatusDetails.new(s) } : []
    end
  end
end
