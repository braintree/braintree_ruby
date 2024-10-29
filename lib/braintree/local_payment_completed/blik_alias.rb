module Braintree
  class LocalPaymentCompleted
    class BlikAlias
      include BaseModule

      attr_reader :key
      attr_reader :label

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end

      def inspect
        attrs = [:key, :label]
        formatted_attrs = attrs.map do |attr|
          "#{attr}: #{send(attr).inspect}"
        end

        "#<#{formatted_attrs.join(", ")}>"
      end
    end
  end
end
