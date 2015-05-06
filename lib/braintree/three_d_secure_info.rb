module Braintree
  class ThreeDSecureInfo # :nodoc:
    include BaseModule

    attr_reader :enrolled, :liability_shifted, :liability_shift_possible, :status
    alias_method :liability_shifted?, :liability_shifted
    alias_method :liability_shift_possible?, :liability_shift_possible

    def initialize(attributes)
      set_instance_variables_from_hash attributes unless attributes.nil?
    end

    def inspect
      attr_order = [:enrolled, :liability_shifted, :liability_shift_possible, :status]
      formatted_attrs = attr_order.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<ThreeDSecureInfo #{formatted_attrs.join(", ")}>"
    end
  end
end
