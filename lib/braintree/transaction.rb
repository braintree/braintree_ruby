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

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create
    def self.create(attributes)
      Util.verify_keys(_create_signature, attributes)
      _do_create "/transactions", :transaction => attributes
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
      params = TransparentRedirect.parse_and_validate_query_string query_string
      _do_create("/transactions/all/confirm_transparent_redirect_request", :id => params[:id])
    end

    # Deprecated. Use Braintree::TransparentRedirect.url
    #
    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_tr
    def self.create_transaction_url
      warn "[DEPRECATED] Transaction.create_transaction_url is deprecated. Please use TransparentRedirect.url"
      "#{Braintree::Configuration.base_merchant_url}/transactions/all/create_via_transparent_redirect_request"
    end

    def self.credit(attributes)
      create(attributes.merge(:type => 'credit'))
    end

    def self.credit!(attributes)
      return_object_or_raise(:transaction) { credit(attributes) }
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/search
    def self.find(id)
      response = Http.get "/transactions/#{id}"
      new(response[:transaction])
    rescue NotFoundError
      raise NotFoundError, "transaction with id #{id.inspect} not found"
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create
    def self.sale(attributes)
      create(attributes.merge(:type => 'sale'))
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create
    def self.sale!(attributes)
      return_object_or_raise(:transaction) { sale(attributes) }
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/search
    def self.search(&block)
      search = TransactionSearch.new
      block.call(search) if block

      response = Http.post "/transactions/advanced_search_ids", {:search => search.to_hash}
      ResourceCollection.new(response) { |ids| _fetch_transactions(search, ids) }
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/submit_for_settlement
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

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/submit_for_settlement
    def self.submit_for_settlement!(transaction_id, amount = nil)
      return_object_or_raise(:transaction) { submit_for_settlement(transaction_id, amount) }
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/void
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

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/void
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

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/refund
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

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/submit_for_settlement
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

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/submit_for_settlement
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

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/void
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

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/void
    def void!
      return_object_or_raise(:transaction) { void }
    end

    class << self
      protected :new
      def _new(*args) # :nodoc:
        self.new *args
      end
    end

    def self._do_create(url, params=nil) # :nodoc:
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
        {
          :billing => Address._shared_signature
        },
        {
          :shipping => Address._shared_signature
        },
        {:options => [:store_in_vault, :submit_for_settlement, :add_billing_address_to_payment_method, :store_shipping_address_in_vault]},
        {:custom_fields => :_any_key_}
      ]
    end

    def self._fetch_transactions(search, ids) # :nodoc:
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
