module Braintree
  # See http://www.braintreepayments.com/docs/ruby/general/result_objects
  class ErrorResult

    attr_reader :credit_card_verification, :merchant_account, :transaction, :subscription, :errors, :params, :message

    def initialize(gateway, data) # :nodoc:
      @gateway = gateway
      @params = data[:params]
      @credit_card_verification = CreditCardVerification._new(data[:verification]) if data[:verification]
      @merchant_account = MerchantAccount._new(gateway, data[:merchant_account]) if data[:merchant_account]
      @message = data[:message]
      @transaction = Transaction._new(gateway, data[:transaction]) if data[:transaction]
      @subscription = Subscription._new(gateway, data[:subscription]) if data[:subscription]
      @errors = Errors.new(data[:errors])
    end

    def inspect # :nodoc:
      if @credit_card_verification
        verification_inspect = " credit_card_verification: #{@credit_card_verification.inspect}"
      end
      if @transaction
        transaction_inspect = " transaction: #{@transaction.inspect}"
      end
      "#<#{self.class} params:{...} errors:<#{@errors._inner_inspect}>#{verification_inspect}#{transaction_inspect}>"
    end

    # Always returns false.
    def success?
      false
    end
  end
end
