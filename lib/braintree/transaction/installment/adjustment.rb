module Braintree
  class Transaction
    class Installment
      class Adjustment
        include BaseModule

        module Kind
          Refund = "REFUND"
          Dispute = "DISPUTE"
        end

        attr_reader :amount
        attr_reader :kind
        attr_reader :projected_disbursement_date
        attr_reader :actual_disbursement_date

        def initialize(attributes)
          set_instance_variables_from_hash attributes unless attributes.nil?
          @amount = Util.to_big_decimal(amount)
        end

        def inspect
          attrs = [:amount, :kind, :projected_disbursement_date, :actual_disbursement_date]
          formatted_attrs = attrs.map do |attr|
            "#{attr}: #{send(attr).inspect}"
          end

          "#<#{formatted_attrs.join(", ")}>"
        end
      end
    end
  end
end
