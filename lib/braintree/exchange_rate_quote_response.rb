module Braintree
  class ExchangeRateQuoteResponse
    include BaseModule

    attr_reader :quotes

    def initialize(attributes)
      @attrs = attributes.keys
      set_instance_variables_from_hash(attributes)
      @quotes = (@quotes || []).map { |quote_hash| ExchangeRateQuote.new(quote_hash) }
    end

    def inspect
      inspected_attributes = @attrs.map { |attr| "#{attr}:#{send(attr).inspect}" }
      "#<#{self.class} #{inspected_attributes.join(" ")}>"
    end
  end
end
