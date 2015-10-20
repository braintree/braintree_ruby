module Braintree
  class Dispute # :nodoc:
    include BaseModule

    attr_reader :amount
    attr_reader :received_date
    attr_reader :reply_by_date
    attr_reader :status
    attr_reader :reason
    attr_reader :currency_iso_code
    attr_reader :id
    attr_reader :transaction_details
    attr_reader :kind
    attr_reader :date_opened
    attr_reader :date_won

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
      @amount = Util.to_big_decimal(amount)
      @transaction_details = TransactionDetails.new(@transaction)
    end
  end
end
