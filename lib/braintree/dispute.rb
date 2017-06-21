module Braintree
  class Dispute # :nodoc:
    include BaseModule

    attr_reader :amount_disputed
    attr_reader :amount_won
    attr_reader :case_number
    attr_reader :created_at
    attr_reader :currency_iso_code
    attr_reader :evidence
    attr_reader :forwarded_comments
    attr_reader :id
    attr_reader :kind
    attr_reader :merchant_account_id
    attr_reader :original_dispute_id
    attr_reader :reason
    attr_reader :reason_code
    attr_reader :reason_description
    attr_reader :received_date
    attr_reader :reference_number
    attr_reader :reply_by_date
    attr_reader :status
    attr_reader :status_history
    attr_reader :transaction
    attr_reader :updated_at

    module Status
      Open = "open"
      Lost = "lost"
      Won = "won"
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
    end

    module Kind
      Chargeback = "chargeback"
      PreArbitration = "pre_arbitration"
      Retrieval = "retrieval"
    end

    class << self
      protected :new
      def _new(*args) # :nodoc:
        self.new *args
      end
    end

    def initialize(attributes) # :nodoc:
      set_instance_variables_from_hash(attributes)
      @received_date = Date.parse(received_date)
      @reply_by_date = Date.parse(reply_by_date) unless reply_by_date.nil?
      @amount_disputed = Util.to_big_decimal(amount_disputed)
      @amount_won = Util.to_big_decimal(amount_won)

      @evidence = evidence.map do |record|
        Braintree::Dispute::Evidence.new(record)
      end unless evidence.nil?

      @transaction = Braintree::Dispute::Transaction.new(transaction)

      @status_history = status_history.map do |event|
        Braintree::Dispute::HistoryEvent.new(event)
      end
    end

    # Returns true if +other+ is a Dispute with the same id
    def ==(other)
      return false unless other.is_a?(Dispute)
      id == other.id
    end
  end
end
