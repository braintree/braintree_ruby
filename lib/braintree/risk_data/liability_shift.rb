module Braintree
  class RiskData
    class LiabilityShift
      include BaseModule

      attr_reader :responsible_party
      attr_reader :conditions

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end

      def inspect
        attr_order = [:responsible_party, :conditions]
        formatted_attrs = attr_order.map do |attr|
          "#{attr}: #{send(attr).inspect}"
        end
        "#<LiabilityShift #{formatted_attrs.join(", ")}>"
      end
    end
  end
end
