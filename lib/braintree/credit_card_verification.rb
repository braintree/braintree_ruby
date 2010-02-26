module Braintree
  class CreditCardVerification
    include BaseModule

    attr_reader :avs_error_response_code, :avs_postal_code_response_code, :avs_street_address_response_code,
      :cvv_response_code, :processor_response_code, :processor_response_text, :status

    def initialize(attributes) # :nodoc:
      set_instance_variables_from_hash(attributes)
    end

    def inspect # :nodoc:
      attr_order = [
        :status, :processor_response_code, :processor_response_text,
        :cvv_response_code, :avs_error_response_code,
        :avs_postal_code_response_code, :avs_street_address_response_code
      ]
      formatted_attrs = attr_order.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<#{self.class} #{formatted_attrs.join(", ")}>"
    end

    class << self
      protected :new
    end

    def self._new(*args) # :nodoc:
      self.new *args
    end
  end
end
