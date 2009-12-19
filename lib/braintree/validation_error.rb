module Braintree
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
