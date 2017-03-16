module Braintree
  class Transaction
    include BaseModule

    module CreatedUsing
      FullInformation = 'full_information'
      Token = 'token'
      Unrecognized = 'unrecognized'
    end

    module EscrowStatus
      HoldPending    = 'hold_pending'
      Held           = 'held'
      ReleasePending = 'release_pending'
      Released       = 'released'
      Refunded       = 'refunded'
      Unrecognized   = 'unrecognized'
    end

    module GatewayRejectionReason
      ApplicationIncomplete = "application_incomplete"
      AVS          = "avs"
      AVSAndCVV    = "avs_and_cvv"
      CVV          = "cvv"
      Duplicate    = "duplicate"
      Fraud        = "fraud"
      ThreeDSecure = "three_d_secure"
      Unrecognized = "unrecognized"
    end

    module Status
      AuthorizationExpired   = 'authorization_expired'
      Authorizing            = 'authorizing'
      Authorized             = 'authorized'
      GatewayRejected        = 'gateway_rejected'
      Failed                 = 'failed'
      ProcessorDeclined      = 'processor_declined'
      Settled                = 'settled'
      SettlementConfirmed    = 'settlement_confirmed'
      SettlementDeclined     = 'settlement_declined'
      SettlementPending      = 'settlement_pending'
      Settling               = 'settling'
      SubmittedForSettlement = 'submitted_for_settlement'
      Voided                 = 'voided'
      Unrecognized           = 'unrecognized'

      All = constants.map { |c| const_get(c) }
    end

    module Source
      Api          = "api"
      ControlPanel = "control_panel"
      Recurring    = "recurring"
      Unrecognized = "unrecognized"
    end

    module IndustryType
      Lodging = "lodging"
      TravelAndCruise = "travel_cruise"

      All = constants.map { |c| const_get(c) }
    end

    module Type # :nodoc:
      Credit = "credit" # :nodoc:
      Sale = "sale" # :nodoc:

      All = constants.map { |c| const_get(c) }
    end

    attr_reader :avs_error_response_code, :avs_postal_code_response_code, :avs_street_address_response_code
    attr_reader :amount, :created_at, :credit_card_details, :customer_details, :subscription_details, :service_fee_amount, :id
    attr_reader :currency_iso_code
    attr_reader :custom_fields
    attr_reader :cvv_response_code
    attr_reader :disbursement_details
    attr_reader :disputes
    attr_reader :descriptor
    attr_reader :escrow_status
    attr_reader :gateway_rejection_reason
    attr_reader :merchant_account_id
    attr_reader :order_id
    attr_reader :channel
    attr_reader :billing_details, :shipping_details
    attr_reader :paypal_details
    attr_reader :apple_pay_details
    attr_reader :android_pay_details
    attr_reader :amex_express_checkout_details
    attr_reader :venmo_account_details
    attr_reader :coinbase_details
    attr_reader :plan_id
    # The authorization code from the processor.
    attr_reader :processor_authorization_code
    # The response code from the processor.
    attr_reader :processor_response_code
    # The response text from the processor.
    attr_reader :processor_response_text
    # The raw response from the processor.
    attr_reader :additional_processor_response
    # The settlement response code from the processor.
    attr_reader :processor_settlement_response_code
    # The settlement response text from the processor.
    attr_reader :processor_settlement_response_text
    attr_reader :voice_referral_number
    attr_reader :purchase_order_number
    attr_reader :recurring
    attr_reader :refund_ids, :refunded_transaction_id
    attr_reader :settlement_batch_id
    attr_reader :authorized_transaction_id
    attr_reader :partial_settlement_transaction_ids
    # See Transaction::Status
    attr_reader :status
    attr_reader :status_history
    attr_reader :subscription_id
    attr_reader :tax_amount
    attr_reader :tax_exempt
    # Will either be "sale" or "credit"
    attr_reader :type
    attr_reader :updated_at
    attr_reader :add_ons, :discounts
    attr_reader :payment_instrument_type
    attr_reader :risk_data
    attr_reader :facilitator_details
    attr_reader :three_d_secure_info
    attr_reader :us_bank_account_details
    attr_reader :ideal_payment_details

    def self.create(attributes)
      Configuration.gateway.transaction.create(attributes)
    end

    def self.create!(attributes)
      return_object_or_raise(:transaction) { create(attributes) }
    end

    def self.cancel_release(transaction_id)
      Configuration.gateway.transaction.cancel_release(transaction_id)
    end

    def self.cancel_release!(transaction_id)
      return_object_or_raise(:transaction) { cancel_release(transaction_id) }
    end

    def self.clone_transaction(transaction_id, attributes)
      Configuration.gateway.transaction.clone_transaction(transaction_id, attributes)
    end

    def self.clone_transaction!(transaction_id, attributes)
      return_object_or_raise(:transaction) { clone_transaction(transaction_id, attributes) }
    end

    # Deprecated. Use Braintree::TransparentRedirect.confirm
    def self.create_from_transparent_redirect(query_string)
      warn "[DEPRECATED] Transaction.create_from_transparent_redirect is deprecated. Please use TransparentRedirect.confirm"
      Configuration.gateway.transaction.create_from_transparent_redirect(query_string)
    end

    # Deprecated. Use Braintree::TransparentRedirect.url
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

    def self.find(id)
      Configuration.gateway.transaction.find(id)
    end

    def self.hold_in_escrow(id)
      Configuration.gateway.transaction.hold_in_escrow(id)
    end

    def self.hold_in_escrow!(id)
      return_object_or_raise(:transaction) { hold_in_escrow(id) }
    end

    def self.refund(id, amount_or_options = nil)
      Configuration.gateway.transaction.refund(id, amount_or_options)
    end

    def self.refund!(id, amount_or_options = nil)
      return_object_or_raise(:transaction) { refund(id, amount_or_options) }
    end

    def self.sale(attributes)
      Configuration.gateway.transaction.sale(attributes)
    end

    def self.sale!(attributes)
      return_object_or_raise(:transaction) { sale(attributes) }
    end

    def self.search(&block)
      Configuration.gateway.transaction.search(&block)
    end

    def self.release_from_escrow(transaction_id)
      Configuration.gateway.transaction.release_from_escrow(transaction_id)
    end

    def self.release_from_escrow!(transaction_id)
      return_object_or_raise(:transaction) { release_from_escrow(transaction_id) }
    end

    def self.submit_for_settlement(transaction_id, amount = nil, options = {})
      Configuration.gateway.transaction.submit_for_settlement(transaction_id, amount, options)
    end

    def self.submit_for_settlement!(transaction_id, amount = nil, options = {})
      return_object_or_raise(:transaction) { submit_for_settlement(transaction_id, amount, options) }
    end

    def self.update_details(transaction_id, options = {})
      Configuration.gateway.transaction.update_details(transaction_id, options)
    end

    def self.update_details!(transaction_id, options = {})
      return_object_or_raise(:transaction) { update_details(transaction_id, options) }
    end

    def self.submit_for_partial_settlement(authorized_transaction_id, amount = nil, options = {})
      Configuration.gateway.transaction.submit_for_partial_settlement(authorized_transaction_id, amount, options)
    end

    def self.submit_for_partial_settlement!(authorized_transaction_id, amount = nil, options = {})
      return_object_or_raise(:transaction) { submit_for_partial_settlement(authorized_transaction_id, amount, options) }
    end

    def self.void(transaction_id)
      Configuration.gateway.transaction.void(transaction_id)
    end

    def self.void!(transaction_id)
      return_object_or_raise(:transaction) { void(transaction_id) }
    end

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @amount = Util.to_big_decimal(amount)
      @credit_card_details = CreditCardDetails.new(@credit_card)
      @service_fee_amount = Util.to_big_decimal(service_fee_amount)
      @subscription_details = SubscriptionDetails.new(@subscription)
      @customer_details = CustomerDetails.new(@customer)
      @billing_details = AddressDetails.new(@billing)
      @disbursement_details = DisbursementDetails.new(@disbursement_details)
      @shipping_details = AddressDetails.new(@shipping)
      @status_history = attributes[:status_history] ? attributes[:status_history].map { |s| StatusDetails.new(s) } : []
      @tax_amount = Util.to_big_decimal(tax_amount)
      @descriptor = Descriptor.new(@descriptor)
      @paypal_details = PayPalDetails.new(@paypal)
      @apple_pay_details = ApplePayDetails.new(@apple_pay)
      @android_pay_details = AndroidPayDetails.new(@android_pay_card)
      @amex_express_checkout_details = AmexExpressCheckoutDetails.new(@amex_express_checkout_card)
      @venmo_account_details = VenmoAccountDetails.new(@venmo_account)
      @coinbase_details = CoinbaseDetails.new(@coinbase_account)
      disputes.map! { |attrs| Dispute._new(attrs) } if disputes
      @custom_fields = attributes[:custom_fields].is_a?(Hash) ? attributes[:custom_fields] : {}
      add_ons.map! { |attrs| AddOn._new(attrs) } if add_ons
      discounts.map! { |attrs| Discount._new(attrs) } if discounts
      @payment_instrument_type = attributes[:payment_instrument_type]
      @risk_data = RiskData.new(attributes[:risk_data]) if attributes[:risk_data]
      @facilitator_details = FacilitatorDetails.new(attributes[:facilitator_details]) if attributes[:facilitator_details]
      @three_d_secure_info = ThreeDSecureInfo.new(attributes[:three_d_secure_info]) if attributes[:three_d_secure_info]
      @us_bank_account_details = UsBankAccountDetails.new(attributes[:us_bank_account]) if attributes[:us_bank_account]
      @ideal_payment_details = IdealPaymentDetails.new(attributes[:ideal_payment]) if attributes[:ideal_payment]
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
          Util.inspect_amount(self.amount)
        else
          "#{attr}: #{send(attr).inspect}"
        end
      end
      "#<#{self.class} #{nice_attributes.join(', ')}>"
    end

    # Deprecated. Use Braintree::Transaction.refund
    def refund(amount = nil)
      warn "[DEPRECATED] refund as an instance method is deprecated. Please use Transaction.refund"
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

    # Returns true if the transaction has been disbursed. False otherwise.
    def disbursed?
      @disbursement_details.valid?
    end

    def refund_id
      warn "[DEPRECATED] Transaction.refund_id is deprecated. Please use Transaction.refund_ids"
      @refund_id
    end

    # Deprecated. Use Braintree::Transaction.submit_for_settlement
    def submit_for_settlement(amount = nil)
      warn "[DEPRECATED] submit_for_settlement as an instance method is deprecated. Please use Transaction.submit_for_settlement"
      result = @gateway.transaction.submit_for_settlement(id, amount)
      if result.success?
        copy_instance_variables_from_object result.transaction
      end
      result
    end

    # Deprecated. Use Braintree::Transaction.submit_for_settlement!
    def submit_for_settlement!(amount = nil)
      warn "[DEPRECATED] submit_for_settlement! as an instance method is deprecated. Please use Transaction.submit_for_settlement!"
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
    def void
      warn "[DEPRECATED] void as an instance method is deprecated. Please use Transaction.void"
      result = @gateway.transaction.void(id)
      if result.success?
        copy_instance_variables_from_object result.transaction
      end
      result
    end

    # Deprecated. Use Braintree::Transaction.void!
    def void!
      warn "[DEPRECATED] void! as an instance method is deprecated. Please use Transaction.void!"
      return_object_or_raise(:transaction) { void }
    end

    class << self
      protected :new
      def _new(*args) # :nodoc:
        self.new *args
      end
    end

    def self._attributes # :nodoc:
      [:amount, :created_at, :credit_card_details, :customer_details, :id, :status, :subscription_details, :type, :updated_at]
    end
  end
end
