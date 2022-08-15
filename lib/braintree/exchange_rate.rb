module Braintree
  class ExchangeRate
    include BaseModule # :nodoc:

    def initialize(gateway, attributes) # :nodoc:
      set_instance_variables_from_hash(attributes)
    end

    def self.generate(exchange_rate_quote_request)
      Configuration.gateway.exchange_rate_quote.generate(exchange_rate_quote_request)
    end
  end
end
