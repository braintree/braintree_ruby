module Braintree
  # See http://www.braintreepaymentsolutions.com/docs/ruby/subscriptions/overview
  class Subscription
    include BaseModule

    module Status
      Active = 'Active'
      Canceled = 'Canceled'
      Expired = 'Expired'
      PastDue = 'Past Due'
    end

    module TrialDurationUnit
      Day = "day"
      Month = "month"
    end

    attr_reader :price, :plan_id, :id, :status, :payment_method_token, :merchant_account_id
    attr_reader :first_billing_date, :next_billing_date, :billing_period_start_date, :billing_period_end_date
    attr_reader :trial_period, :trial_duration, :trial_duration_unit
    attr_reader :failure_count
    attr_reader :transactions
    attr_reader :next_bill_amount
    attr_reader :number_of_billing_cycles
    attr_reader :add_ons, :discounts

    # See http://www.braintreepaymentsolutions.com/docs/ruby/subscriptions/cancel
    def self.cancel(subscription_id)
      response = Http.put "/subscriptions/#{subscription_id}/cancel"
      if response[:subscription]
        SuccessfulResult.new(:subscription => _new(response[:subscription]))
      elsif response[:api_error_response]
        ErrorResult.new(response[:api_error_response])
      else
        raise UnexpectedError, "expected :subscription or :api_error_response"
      end
    rescue NotFoundError
      raise NotFoundError, "subscription with id #{subscription_id.inspect} not found"
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/subscriptions/create
    def self.create(attributes)
      Util.verify_keys(_create_signature, attributes)
      _do_create "/subscriptions", :subscription => attributes
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/subscriptions/search
    def self.find(id)
      response = Http.get "/subscriptions/#{id}"
      _new(response[:subscription])
    rescue NotFoundError
      raise NotFoundError, "subscription with id #{id.inspect} not found"
    end

    def self.retry_charge(subscription_id, amount=nil)
      attributes = {
        :amount => amount,
        :subscription_id => subscription_id,
        :type => Transaction::Type::Sale
      }

      Transaction.send(:_do_create, "/transactions", :transaction => attributes)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/subscriptions/search
    def self.search(&block)
      search = SubscriptionSearch.new
      block.call(search) if block

      response = Http.post "/subscriptions/advanced_search_ids", {:search => search.to_hash}
      ResourceCollection.new(response) { |ids| _fetch_subscriptions(search, ids) }
    end

    def self._fetch_subscriptions(search, ids) # :nodoc:
      search.ids.in ids
      response = Http.post "/subscriptions/advanced_search", {:search => search.to_hash}
      attributes = response[:subscriptions]
      Util.extract_attribute_as_array(attributes, :subscription).map { |attrs| _new(attrs) }
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/subscriptions/update
    def self.update(subscription_id, attributes)
      Util.verify_keys(_update_signature, attributes)
      response = Http.put "/subscriptions/#{subscription_id}", :subscription => attributes
      if response[:subscription]
        SuccessfulResult.new(:subscription => _new(response[:subscription]))
      elsif response[:api_error_response]
         ErrorResult.new(response[:api_error_response])
      else
        raise UnexpectedError, "expected :subscription or :api_error_response"
      end
    end

    def self._create_signature # :nodoc:
      [
        :id,
        :merchant_account_id,
        :never_expires,
        :number_of_billing_cycles,
        :payment_method_token,
        :plan_id,
        :price,
        :trial_duration,
        :trial_duration_unit,
        :trial_period,
        {:options => [:do_not_inherit_add_ons_or_discounts]},
      ] + _add_on_discount_signature
    end

    def initialize(attributes) # :nodoc:
      _init attributes
      transactions.map! { |attrs| Transaction._new(attrs) }
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

    def self._do_create(url, params) # :nodoc:
      response = Http.post url, params
      if response[:subscription]
        SuccessfulResult.new(:subscription => new(response[:subscription]))
      elsif response[:api_error_response]
        ErrorResult.new(response[:api_error_response])
      else
        raise UnexpectedError, "expected :subscription or :api_error_response"
      end
    end

    def _init(attributes) # :nodoc:
      set_instance_variables_from_hash(attributes)
      @price = Util.to_big_decimal(price)
    end

    def self._update_signature # :nodoc:
      [
        :id,
        :merchant_account_id,
        :never_expires,
        :number_of_billing_cycles,
        :payment_method_token,
        :plan_id,
        :price,
        {:options => [:replace_all_add_ons_and_discounts]},
      ] + _add_on_discount_signature
    end

    def self._add_on_discount_signature # :nodoc:
      [
        {
          :add_ons => [
            {:add => [:amount, :inherited_from_id, :never_expires, :number_of_billing_cycles, :quantity]},
            {:update => [:amount, :existing_id, :never_expires, :number_of_billing_cycles, :quantity]},
            {:remove => [:_any_key_]}
          ]
        },
        {
          :discounts => [
            {:add => [:amount, :inherited_from_id, :never_expires, :number_of_billing_cycles, :quantity]},
            {:update => [:amount, :existing_id, :never_expires, :number_of_billing_cycles, :quantity]},
            {:remove => [:_any_key_]}
          ]
        }
      ]
    end
  end
end
