module Braintree
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

    attr_reader :price, :plan_id, :id, :status, :payment_method_token
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
      if self.price
        instance_variable_set :@price, BigDecimal.new(self.price)
      end  
    end

    def self._update_signature # :nodoc:
      [
        :id,
        :plan_id,
        :price
      ]
    end
  end
end
