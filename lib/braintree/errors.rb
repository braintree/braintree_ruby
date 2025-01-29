module Braintree
  class Errors
    include Enumerable

    def initialize(data = {})
      data = data.merge(:errors => []) unless data
      @errors = ValidationErrorCollection.new(data)
    end

    def each(&block)
      @errors.deep_errors.each(&block)
    end

    def for(scope)
      @errors.for(scope)
    end

    def inspect
      "#<#{self.class} #{_inner_inspect}>"
    end

    # Returns the total number of validation errors at all levels of nesting. For example,
    # if creating a customer with a credit card and a billing address, and each of the customer,
    # credit card, and billing address has 1 error, this method will return 3.
    def size
      @errors.deep_size
    end

    def _inner_inspect
      @errors._inner_inspect
    end
  end
end

