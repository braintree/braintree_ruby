module Braintree
  class Transfer
    include BaseModule

    attr_reader :id, :message, :disbursement_date, :follow_up_action, :merchant_account_id

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
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

    class << self
      protected :new
      def _new(*args) # :nodoc:
        self.new *args
      end
    end
  end
end
