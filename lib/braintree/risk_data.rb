module Braintree
  class RiskData # :nodoc:
    include BaseModule

    attr_reader :id, :decision

    def initialize(attributes)
      set_instance_variables_from_hash attributes unless attributes.nil?
    end

    def inspect
      attr_order = [:id, :decision]
      formatted_attrs = attr_order.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<RiskData #{formatted_attrs.join(", ")}>"
    end
  end
end
