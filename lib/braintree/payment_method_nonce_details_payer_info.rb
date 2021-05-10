module Braintree
  class PaymentMethodNonceDetailsPayerInfo # :nodoc:
    include BaseModule

    attr_reader :billing_agreement_id
    attr_reader :country_code
    attr_reader :email
    attr_reader :first_name
    attr_reader :last_name
    attr_reader :payer_id

    def initialize(attributes)
      set_instance_variables_from_hash attributes unless attributes.nil?
    end

    def inspect
      attr_order = [
        :billing_agreement_id,
        :country_code,
        :email,
        :first_name,
        :last_name,
        :payer_id,
      ]

      formatted_attrs = attr_order.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<PaymentMethodNonceDetailsPayerInfo #{formatted_attrs.join(", ")}>"
    end
  end
end
