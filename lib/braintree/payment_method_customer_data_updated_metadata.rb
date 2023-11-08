module Braintree
  class PaymentMethodCustomerDataUpdatedMetadata
    include BaseModule

    attr_reader :token
    attr_reader :payment_method
    attr_reader :datetime_updated
    attr_reader :enriched_customer_data

    def initialize(gateway, attributes)
      set_instance_variables_from_hash(attributes)
      @payment_method = PaymentMethodParser.parse_payment_method(gateway, attributes[:payment_method])
      @enriched_customer_data = EnrichedCustomerData._new(enriched_customer_data) if enriched_customer_data
    end

    class << self
      protected :new
    end

    def self._new(*args)
      self.new(*args)
    end
  end
end
