module Braintree
  class RiskData # :nodoc:
    include BaseModule

    attr_reader :decision
    attr_reader :device_data_captured
    attr_reader :id

    def initialize(attributes)
      set_instance_variables_from_hash attributes unless attributes.nil?
    end

    def inspect
      attr_order = [:id, :decision, :device_data_captured]
      formatted_attrs = attr_order.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<RiskData #{formatted_attrs.join(", ")}>"
    end
  end
end
