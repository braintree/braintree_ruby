module Braintree
  class PlanGateway # :nodoc:
    include BaseModule

    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
      @config.assert_has_access_token_or_keys
    end

    def all
      response = @config.http.get("#{@config.base_merchant_path}/plans")
      attributes_collection = response[:plans] || []
      attributes_collection.map do |attributes|
        Plan._new(@gateway, attributes)
      end
    end

    def create(attributes)
      Util.verify_keys(PlanGateway._create_signature, attributes)
      _do_create "/plans", :plan => attributes
    end

    def create!(*args)
      return_object_or_raise(:plan) { create(*args) }
    end

    def find(id)
      raise ArgumentError if id.nil? || id.to_s.strip == ""
      response = @config.http.get("#{@config.base_merchant_path}/plans/#{id}")
      Plan._new(@gateway, response[:plan])
    rescue NotFoundError
      raise NotFoundError, "plan with id #{id.inspect} not found"
    end

    def update(plan_id, attributes)
      Util.verify_keys(PlanGateway._update_signature, attributes)
      response = @config.http.put("#{@config.base_merchant_path}/plans/#{plan_id}", :plan => attributes)
      if response[:plan]
        SuccessfulResult.new(:plan => Plan._new(@gateway, response[:plan]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :plan or :api_error_response"
      end
    end

    def update!(*args)
      return_object_or_raise(:plan) { update(*args) }
    end

    def self._create_signature
      [
        :billing_day_of_month,
        :billing_frequency,
        :currency_iso_code,
        :description,
        :id,
        :merchant_id,
        :name,
        :number_of_billing_cycles,
        :price,
        :trial_duration,
        :trial_duration_unit,
        :trial_period
      ] + _add_on_discount_signature
    end

    def self._update_signature
      [
        :billing_day_of_month,
        :billing_frequency,
        :currency_iso_code,
        :description,
        :id,
        :merchant_id,
        :name,
        :number_of_billing_cycles,
        :price,
        :trial_duration,
        :trial_duration_unit,
        :trial_period
      ] + _add_on_discount_signature
    end

    def self._add_on_discount_signature
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

    def _do_create(path, params) # :nodoc:
      response = @config.http.post("#{@config.base_merchant_path}#{path}", params)
      if response[:plan]
        SuccessfulResult.new(:plan => Plan._new(@gateway, response[:plan]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :plan or :api_error_response"
      end
    end
  end
end

