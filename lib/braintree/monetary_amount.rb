module Braintree
  class MonetaryAmount
    include BaseModule

    attr_reader :currency_code
    attr_reader :value

    def initialize(attributes)
      set_instance_variables_from_hash(attributes)
    end

    def inspect
      "#<MonetaryAmount currency_code:#{currency_code.inspect} value:#{value.inspect}>"
    end

    class << self
      protected :new
    end

    def self._new(*args)
      self.new(*args)
    end
  end
end
