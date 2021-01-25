module Braintree
  class Transaction
    class Installment
      include BaseModule

      attr_reader :id
      attr_reader :amount
      attr_reader :projected_disbursement_date
      attr_reader :actual_disbursement_date
      attr_reader :adjustments

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
        @amount = Util.to_big_decimal(amount)
        adjustments.map! { |attrs| Adjustment.new(attrs) } if adjustments
      end

      def inspect
        attrs = [:id, :amount, :projected_disbursement_date, :actual_disbursement_date, :adjustments]
        formatted_attrs = attrs.map do |attr|
          "#{attr}: #{send(attr).inspect}"
        end

        "#<#{formatted_attrs.join(", ")}>"
      end
    end
  end
end
