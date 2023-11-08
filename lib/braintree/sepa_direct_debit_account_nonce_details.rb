module Braintree
  class SepaDirectDebitAccountNonceDetails
    include BaseModule

    attr_reader :bank_reference_token
    attr_reader :last_4
    attr_reader :mandate_type
    attr_reader :merchant_or_partner_customer_id

    def initialize(attributes)
      set_instance_variables_from_hash attributes unless attributes.nil?
    end

    def inspect
      attr_order = [
        :bank_reference_token,
        :last_4,
        :mandate_type,
        :merchant_or_partner_customer_id,
      ]

      formatted_attrs = attr_order.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<SepaDirectDebitAccountNonceDetails#{formatted_attrs.join(", ")}>"
    end
  end
end
