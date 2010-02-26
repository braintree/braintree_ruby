module Braintree
  class Transaction
    class CustomerDetails # :nodoc:
      include BaseModule

      attr_reader :company, :email, :fax, :first_name, :id, :last_name, :phone, :website

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end

      def inspect
        attr_order = [:id, :first_name, :last_name, :email, :company, :website, :phone, :fax]
        formatted_attrs = attr_order.map do |attr|
          "#{attr}: #{send(attr).inspect}"
        end
        "#<#{formatted_attrs.join(", ")}>"
      end
    end
  end
end
