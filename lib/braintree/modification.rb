module Braintree
  class Modification
    include BaseModule

    attr_reader :amount, :id, :number_of_billing_cycles, :quantity

    class << self
      protected :new
      def _new(*args) # :nodoc:
        self.new *args
      end
    end

    def initialize(attributes) # :nodoc:
      _init attributes
    end

    def never_expires?
      @never_expires
    end

    def _init(attributes) # :nodoc:
      set_instance_variables_from_hash(attributes)
      @amount = Util.to_big_decimal(amount)
    end
  end
end
