module Braintree
  class LocalPaymentCompleted
    include BaseModule

    attr_reader :bic
    attr_reader :blik_aliases
    attr_reader :iban_last_chars
    attr_reader :payer_id
    attr_reader :payer_name
    attr_reader :payment_id
    attr_reader :payment_method_nonce
    attr_reader :transaction

    def initialize(attributes)
      set_instance_variables_from_hash(attributes)
      @transaction = Transaction._new(Configuration.gateway, transaction) unless transaction.nil?
      blik_aliases.map { |attrs| BlikAlias.new(attrs) } if blik_aliases
    end

    class << self
      protected :new
    end

    def self._new(*args)
      self.new(*args)
    end
  end
end
