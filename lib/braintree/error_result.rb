module Braintree
  # An ErrorResult will be returned from non-bang methods when
  # validations fail. It will provide access to the params passed
  # to the server. The params are primarily useful for re-populaing
  # web forms when using transparent redirect. ErrorResult also
  # provides access to the validation errors.
  #
  #   result = Braintree::Customer.create(:email => "invalid.email.address")
  #   if result.success?
  #     # have a SuccessfulResult
  #   else
  #     # have an ErrorResult
  #     puts "Validations failed when attempting to create customer."
  #     result.errors.for(:customer).each do |error|
  #       puts error.message
  #     end
  #   end
  class ErrorResult

    attr_reader :credit_card_verification, :transaction, :errors, :params, :message

    def initialize(data) # :nodoc:
      @params = data[:params]
      @credit_card_verification = CreditCardVerification._new(data[:verification]) if data[:verification]
      @message = data[:message]
      @transaction = Transaction._new(data[:transaction]) if data[:transaction]
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
