module Braintree
  class Disbursement
    include BaseModule

    attr_reader :id, :amount, :exception_message, :disbursement_date, :follow_up_action, :merchant_account, :transaction_ids, :retry, :success

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @amount = Util.to_big_decimal(amount)
      @disbursement_date = Date.parse(disbursement_date)
      @merchant_account = MerchantAccount._new(gateway, @merchant_account)
    end

    def transactions
      transactions = @gateway.transaction.search do |search|
        search.ids.in transaction_ids
      end
    end

    def inspect # :nodoc:
      nice_attributes = self.class._inspect_attributes.map { |attr| "#{attr}: #{send(attr).inspect}" }
      nice_attributes << "amount: #{self.amount.to_s("F").inspect}"
      nice_attributes << "disbursement_date: #{self.disbursement_date.to_s}"
      "#<#{self.class} #{nice_attributes.join(', ')}>"
    end

    class << self
      protected :new
      def _new(*args) # :nodoc:
        self.new *args
      end
    end

    def self._inspect_attributes # :nodoc:
      [:id, :exception_message, :follow_up_action, :merchant_account, :transaction_ids, :retry, :success]
    end
  end
end
