module Braintree
  class ExchangeRateQuote
    include BaseModule # :nodoc:

    attr_reader :attrs
    attr_reader :base_amount
    attr_reader :exchange_rate
    attr_reader :expires_at
    attr_reader :id
    attr_reader :quote_amount
    attr_reader :refreshes_at
    attr_reader :trade_rate

    def initialize(attributes) # :nodoc:
      @attrs = attributes.keys
      set_instance_variables_from_hash(attributes)
    end

    def inspect # :nodoc:
      inspected_attributes = @attrs.map { |attr| "#{attr}:#{send(attr).inspect}" }
      "#<#{self.class} #{inspected_attributes.join(" ")}>"
    end
  end
end
