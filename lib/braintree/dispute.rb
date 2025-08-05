module Braintree
  class Dispute
    include BaseModule
    include Braintree::Util::IdEquality

    attr_reader :amount
    attr_reader :amount_disputed
    attr_reader :amount_won
    attr_reader :case_number
    # NEXT_MAJOR_VERSION Remove this attribute
    # DEPRECATED The chargeback_protection_level attribute is deprecated in favor of protection_level
    attr_reader :chargeback_protection_level #Deprecated
    attr_reader :created_at
    attr_reader :currency_iso_code
    attr_reader :date_opened
    attr_reader :date_won
    attr_reader :evidence
    attr_reader :graphql_id
    attr_reader :id
    attr_reader :kind
    attr_reader :merchant_account_id
    attr_reader :original_dispute_id
    attr_reader :paypal_messages
    attr_reader :pre_dispute_program
    attr_reader :processor_comments
    attr_reader :protection_level
    attr_reader :reason
    attr_reader :reason_code
    attr_reader :reason_description
    attr_reader :received_date
    attr_reader :reference_number
    attr_reader :reply_by_date
    attr_reader :status
    attr_reader :status_history
    attr_reader :remaining_file_evidence_storage
    attr_reader :transaction
    attr_reader :transaction_details
    attr_reader :updated_at

    module Status
      Accepted = "accepted"
      AutoAccepted = "auto_accepted"
      Disputed = "disputed"
      Expired = "expired"
      Open = "open"
      Lost = "lost"
      UnderReview = "under_review"
      Won = "won"

      All = constants.map { |c| const_get(c) }
    end

    module Reason
      CancelledRecurringTransaction = "cancelled_recurring_transaction"
      CreditNotProcessed = "credit_not_processed"
      Duplicate = "duplicate"
      Fraud = "fraud"
      General = "general"
      InvalidAccount = "invalid_account"
      NotRecognized = "not_recognized"
      ProductNotReceived = "product_not_received"
      ProductUnsatisfactory = "product_unsatisfactory"
      TransactionAmountDiffers = "transaction_amount_differs"
      Retrieval = "retrieval"

      All = constants.map { |c| const_get(c) }
    end

    module Kind
      Chargeback = "chargeback"
      PreArbitration = "pre_arbitration"
      Retrieval = "retrieval"

      All = constants.map { |c| const_get(c) }
    end

    module ChargebackProtectionLevel
      Effortless = "effortless"
      Standard = "standard"
      NotProtected = "not_protected"

      All = constants.map { |c| const_get(c) }
    end

    module ProtectionLevel
      EffortlessCBP = "Effortless Chargeback Protection tool"
      StandardCBP = "Chargeback Protection tool"
      NoProtection = "No Protection"

      All = constants.map { |c| const_get(c) }
    end

    module PreDisputeProgram
      None = "none"
      VisaRdr = "visa_rdr"

      All = constants.map { |c| const_get(c) }
    end

    class << self
      protected :new
      def _new(*args)
        self.new(*args)
      end
    end

    def self.accept(*args)
      Configuration.gateway.dispute.accept(*args)
    end

    def self.add_file_evidence(*args)
      Configuration.gateway.dispute.add_file_evidence(*args)
    end

    def self.add_text_evidence(*args)
      Configuration.gateway.dispute.add_text_evidence(*args)
    end

    def self.finalize(*args)
      Configuration.gateway.dispute.finalize(*args)
    end

    def self.find(*args)
      Configuration.gateway.dispute.find(*args)
    end

    def self.remove_evidence(*args)
      Configuration.gateway.dispute.remove_evidence(*args)
    end

    def self.search(&block)
      Configuration.gateway.dispute.search(&block)
    end

    def initialize(attributes)
      set_instance_variables_from_hash(attributes)
      @date_opened = Date.parse(date_opened) unless date_opened.nil?
      @date_won = Date.parse(date_won) unless date_won.nil?
      @received_date = Date.parse(received_date)
      @reply_by_date = Date.parse(reply_by_date) unless reply_by_date.nil?
      @amount = Util.to_big_decimal(amount)
      @amount_disputed = Util.to_big_decimal(amount_disputed)
      @amount_won = Util.to_big_decimal(amount_won)
      if (ChargebackProtectionLevel::All - [ChargebackProtectionLevel::NotProtected]).include?(chargeback_protection_level)
        @protection_level = Dispute.const_get("ProtectionLevel::#{chargeback_protection_level.capitalize}CBP")
      else
        @protection_level = ProtectionLevel::NoProtection
      end

      @evidence = evidence.map do |record|
        Braintree::Dispute::Evidence.new(record)
      end unless evidence.nil?

      @paypal_messages = paypal_messages.map do |record|
        Braintree::Dispute::PayPalMessage.new(record)
      end unless paypal_messages.nil?

      @transaction_details = TransactionDetails.new(transaction)
      @transaction = Transaction.new(transaction)

      @status_history = status_history.map do |event|
        Braintree::Dispute::StatusHistory.new(event)
      end unless status_history.nil?
    end
  end
end
