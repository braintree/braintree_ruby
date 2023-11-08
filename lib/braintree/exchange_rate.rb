module Braintree
  class ExchangeRate
    include BaseModule

    def initialize(gateway, attributes)
      set_instance_variables_from_hash(attributes)
    end

    def self.generate(exchange_rate_quote_request)
      Configuration.gateway.exchange_rate_quote.generate(exchange_rate_quote_request)
    end
  end
end
