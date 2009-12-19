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
  
    attr_reader :credit_card_verification, :errors, :params 
  
    def initialize(data) # :nodoc:
      @params = data[:params]
      if data[:verification]
        @credit_card_verification = CreditCardVerification._new(data[:verification])
      end
      @errors = Errors.new(data[:errors])
    end

    def inspect # :nodoc:
      "#<#{self.class} params:{...} errors:<#{@errors._inner_inspect}>>"
    end
    
    # Always returns false.
    def success?
      false
    end
  end
end
