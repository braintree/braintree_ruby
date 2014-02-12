module Braintree
  class Transfer
    include BaseModule

    attr_reader :amount, :id, :message, :disbursement_date, :follow_up_action, :merchant_account_id

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @amount = Util.to_big_decimal(amount)
    end

    def merchant_account
      @merchant_account ||= @gateway.merchant_account.find(merchant_account_id)
    end

    def transactions
      @gateway.transaction.search do |search|
        search.merchant_account_id.is merchant_account_id
        search.disbursement_date.is disbursement_date
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
      [:id, :amount, :message, :disbursement_date, :follow_up_action]
    end
  end
end
