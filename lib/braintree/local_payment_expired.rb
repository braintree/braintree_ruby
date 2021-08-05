module Braintree
  class LocalPaymentExpired
    include BaseModule

    attr_reader :payment_id
    attr_reader :payment_context_id

    def initialize(attributes) # :nodoc:
      set_instance_variables_from_hash(attributes)
    end

    class << self
      protected :new
    end

    def self._new(*args) # :nodoc:
      self.new(*args)
    end
  end
end

