module Braintree
  class Transaction
    class DepositDetails # :nodoc:
      include BaseModule

      attr_reader :deposit_date, :disbursed_at, :settlement_amount, :settlement_currency_iso_code, :settlement_currency_exchange_rate

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end

      def funds_held?
        @funds_held
      end

      def valid?
        !deposit_date.nil?
      end
    end
  end
end
