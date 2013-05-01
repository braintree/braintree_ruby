module Braintree
  class Transaction
    class DisbursementDetails # :nodoc:
      include BaseModule

      attr_reader :disbursement_date, :settlement_amount, :settlement_currency_iso_code, :settlement_currency_exchange_rate

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end

      def funds_held?
        @funds_held
      end

      def valid?
        !disbursement_date.nil?
      end
    end
  end
end
