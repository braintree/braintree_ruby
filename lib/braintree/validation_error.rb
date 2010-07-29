module Braintree
  # See http://www.braintreepaymentsolutions.com/docs/ruby/general/validation_errors
  class ValidationError
    include BaseModule

    attr_reader :attribute, :code, :message

    def initialize(attributes)
      set_instance_variables_from_hash attributes
    end

    def inspect # :nodoc:
      "#<#{self.class} (#{code}) #{message}>"
    end
  end
end
