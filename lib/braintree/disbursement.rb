module Braintree
  class Disbursement
    include BaseModule

    attr_reader :id, :amount, :exception_message, :disbursement_date, :follow_up_action, :merchant_account, :transaction_ids, :retry, :success

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @amount = Util.to_big_decimal(amount)
      @merchant_account = MerchantAccount._new(gateway, @merchant_account)
    end

    def transactions
      transactions = @gateway.transaction.search do |search|
        search.ids.in transaction_ids
      end
    end

    def inspect # :nodoc:
      nice_attributes = self.class._attributes.map do |attr|
        if attr == :amount
          "amount: #{self.amount.to_s("F").inspect}"
        elsif attr == :disbursement_date
          "disbursement_date: #{self.disbursement_date.to_s}"
        else
          "#{attr}: #{send(attr).inspect}"
        end
      end
      "#<#{self.class} #{nice_attributes.join(', ')}>"
    end

    class << self
      protected :new
      def _new(*args) # :nodoc:
        self.new *args
      end
    end

    def self._attributes # :nodoc:
      [:id, :amount, :exception_message, :disbursement_date, :follow_up_action, :merchant_account, :transaction_ids, :retry, :success]
    end
  end
end
