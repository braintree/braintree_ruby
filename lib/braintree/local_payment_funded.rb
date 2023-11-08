module Braintree
  class LocalPaymentFunded
    include BaseModule

    attr_reader :payment_id
    attr_reader :payment_context_id
    attr_reader :transaction

    def initialize(attributes)
      set_instance_variables_from_hash(attributes)
      @transaction = Transaction._new(Configuration.gateway, transaction)
    end

    class << self
      protected :new
    end

    def self._new(*args)
      self.new(*args)
    end
  end
end
