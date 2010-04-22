module Braintree
  # == Creating a Subscription
  #
  # At minimum, a plan_id and payment_method_token are required. Any other values not
  # provided will be defaulted to the plan's values:
  #
  #  Braintree::Subscription.create(
  #    :payment_method_token => "my_token",
  #    :plan_id => "my_plan"
  #  )
  #
  # Full example:
  #
  #  Braintree::Subscription.create(
  #    :id => "my_id",
  #    :payment_method_token => "my_token",
  #    :plan_id => "my_plan",
  #    :price => "1.00",
  #    :trial_period => true,
  #    :trial_duration => "2",
  #    :trial_duration_unit => Subscription::TrialDurationUnit::Day
  #  )
  #
  # == More Information
  #
  # For more detailed documentation on Subscriptions, see http://www.braintreepaymentsolutions.com/gateway/subscription-api
  class Subscription
    include BaseModule

    module Status
      Active = 'Active'
      Canceled = 'Canceled'
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

    def self.cancel(subscription_id)
      response = Http.put "/subscriptions/#{subscription_id}/cancel"
      if response[:subscription]
        SuccessfulResult.new(:subscription => new(response[:subscription]))
      elsif response[:api_error_response]
        ErrorResult.new(response[:api_error_response])
      else
        raise UnexpectedError, "expected :subscription or :api_error_response"
      end
    rescue NotFoundError
      raise NotFoundError, "subscription with id #{subscription_id.inspect} not found"
    end

    def self.create(attributes)
      Util.verify_keys(_create_signature, attributes)
      _do_create "/subscriptions", :subscription => attributes
    end

    # Finds the subscription with the given id. Raises a Braintree::NotFoundError
    # if the subscription cannot be found.
    def self.find(id)
      response = Http.get "/subscriptions/#{id}"
      new(response[:subscription])
    rescue NotFoundError
      raise NotFoundError, "subscription with id #{id.inspect} not found"
    end

    # Allows searching on subscriptions. There are two types of fields that are searchable: text and
    # multiple value fields. Searchable text fields are:
    # - plan_id
    # - days_past_due
    #
    # Searchable multiple value fields are:
    # - status
    #
    # For text fields, you can search using the following operators: is, is_not, starts_with, ends_with
    # and contains. For mutiple value fields, you can search using the in operator. An example:
    #
    #  Subscription.search do |s|
    #    s.plan_id.starts_with "abc"
    #    s.days_past_due.is "30"
    #    s.status.in [Subscription::Status::PastDue]
    #  end
    def self.search(page=1, &block)
      search = SubscriptionSearch.new
      block.call(search)

      response = Http.post "/subscriptions/advanced_search?page=#{page}", {:search => search.to_hash}
      attributes = response[:subscriptions]
      attributes[:items] = Util.extract_attribute_as_array(attributes, :subscription).map { |attrs| new(attrs) }
      ResourceCollection.new(attributes) { |page_number| Subscription.search(page_number, &block) }
    end

    def self.update(subscription_id, attributes)
      Util.verify_keys(_update_signature, attributes)
      response = Http.put "/subscriptions/#{subscription_id}", :subscription => attributes
      if response[:subscription]
        SuccessfulResult.new(:subscription => new(response[:subscription]))
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
        :payment_method_token,
        :plan_id,
        :price,
        :trial_duration,
        :trial_duration_unit,
        :trial_period
      ]
    end

    def initialize(attributes) # :nodoc:
      _init attributes
      transactions.map! {|attrs| Transaction._new(attrs) }
    end


    # True if <tt>other</tt> has the same id.
    def ==(other)
      id == other.id
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
        :plan_id,
        :price
      ]
    end
  end
end
