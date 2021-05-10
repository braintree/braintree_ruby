module Braintree
  class PaymentMethodNonceDetails # :nodoc:
    include BaseModule

    attr_reader :bin
    attr_reader :card_type
    attr_reader :expiration_month
    attr_reader :expiration_year
    attr_reader :is_network_tokenized
    attr_reader :last_two
    attr_reader :payer_info

    alias_method :is_network_tokenized?, :is_network_tokenized

    def initialize(attributes)
      set_instance_variables_from_hash attributes unless attributes.nil?
      @payer_info = PaymentMethodNonceDetailsPayerInfo.new(attributes[:payer_info]) if attributes[:payer_info]
    end

    def inspect
      attr_order = [
        :bin,
        :card_type,
        :expiration_month,
        :expiration_year,
        :is_network_tokenized,
        :last_two,
        :payer_info,
      ]

      formatted_attrs = attr_order.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<PaymentMethodNonceDetails #{formatted_attrs.join(", ")}>"
    end
  end
end
