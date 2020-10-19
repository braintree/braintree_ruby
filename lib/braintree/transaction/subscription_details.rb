module Braintree
  class Transaction
    class SubscriptionDetails # :nodoc:
      include BaseModule

      attr_reader :billing_period_end_date
      attr_reader :billing_period_start_date

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
        @billing_period_start_date = Date.parse(billing_period_start_date) unless billing_period_start_date.nil?
        @billing_period_end_date = Date.parse(billing_period_end_date) unless billing_period_end_date.nil?
      end
    end
  end
end
