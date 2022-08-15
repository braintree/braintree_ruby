module Braintree
  class ExchangeRateQuoteInput
    include BaseModule # :nodoc:

    attr_reader :attrs
    attr_reader :base_currency
    attr_reader :base_amount
    attr_reader :markup
    attr_reader :quote_currency

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
