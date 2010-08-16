module Braintree
  # See http://www.braintreepaymentsolutions.com/docs/ruby/subscriptions/overview
  class Subscription
    include BaseModule

    module Status
      Active = 'Active'
      Canceled = 'Canceled'
      Expired = 'Expired'
      PastDue = 'Past Due'
      Pending = 'Pending'

      All = constants.map { |c| const_get(c) }
    end

    module TrialDurationUnit
      Day = "day"
      Month = "month"
    end

    attr_reader :days_past_due, :price, :plan_id, :id, :status, :payment_method_token, :merchant_account_id
    attr_reader :first_billing_date, :next_billing_date, :billing_period_start_date, :billing_period_end_date
    attr_reader :trial_period, :trial_duration, :trial_duration_unit
    attr_reader :failure_count
    attr_reader :transactions
    attr_reader :next_bill_amount
    attr_reader :number_of_billing_cycles, :billing_day_of_month
    attr_reader :add_ons, :discounts

    # See http://www.braintreepaymentsolutions.com/docs/ruby/subscriptions/cancel
    def self.cancel(subscription_id)
      Configuration.gateway.subscription.cancel(subscription_id)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/subscriptions/create
    def self.create(attributes)
      Configuration.gateway.subscription.create(attributes)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/subscriptions/search
    def self.find(id)
      Configuration.gateway.subscription.find(id)
    end

    def self.retry_charge(subscription_id, amount=nil)
      Configuration.gateway.transaction.retry_subscription_charge(subscription_id, amount)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/subscriptions/search
    def self.search(&block)
      Configuration.gateway.subscription.search(&block)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/subscriptions/update
    def self.update(subscription_id, attributes)
      Configuration.gateway.subscription.update(subscription_id, attributes)
    end

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @price = Util.to_big_decimal(price)
      transactions.map! { |attrs| Transaction._new(gateway, attrs) }
      add_ons.map! { |attrs| AddOn._new(attrs) }
      discounts.map! { |attrs| Discount._new(attrs) }
    end

    def never_expires?
      @never_expires
    end

    # True if <tt>other</tt> has the same id.
    def ==(other)
      return false unless other.is_a?(Subscription)
      id == other.id
    end

    class << self
      protected :new
      def _new(*args) # :nodoc:
        self.new *args
      end
    end
  end
end
