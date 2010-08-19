module Braintree
  class Modification # :nodoc:
    include BaseModule

    attr_reader :amount, :id, :number_of_billing_cycles, :quantity

    class << self
      protected :new
      def _new(*args) # :nodoc:
        self.new *args
      end
    end

    def initialize(attributes) # :nodoc:
      set_instance_variables_from_hash(attributes)
      @amount = Util.to_big_decimal(amount)
    end

    def never_expires?
      @never_expires
    end
  end
end
