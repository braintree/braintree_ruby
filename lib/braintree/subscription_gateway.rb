module Braintree
  class SubscriptionGateway # :nodoc:
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def cancel(subscription_id)
      response = @config.http.put "/subscriptions/#{subscription_id}/cancel"
      if response[:subscription]
        SuccessfulResult.new(:subscription => Subscription._new(@gateway, response[:subscription]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :subscription or :api_error_response"
      end
    rescue NotFoundError
      raise NotFoundError, "subscription with id #{subscription_id.inspect} not found"
    end

    def create(attributes)
      Util.verify_keys(SubscriptionGateway._create_signature, attributes)
      _do_create "/subscriptions", :subscription => attributes
    end

    def find(id)
      raise ArgumentError if id.nil? || id.to_s.strip == ""
      response = @config.http.get "/subscriptions/#{id}"
      Subscription._new(@gateway, response[:subscription])
    rescue NotFoundError
      raise NotFoundError, "subscription with id #{id.inspect} not found"
    end

    def search(&block)
      search = SubscriptionSearch.new
      block.call(search) if block

      response = @config.http.post "/subscriptions/advanced_search_ids", {:search => search.to_hash}
      ResourceCollection.new(response) { |ids| _fetch_subscriptions(search, ids) }
    end

    def update(subscription_id, attributes)
      Util.verify_keys(SubscriptionGateway._update_signature, attributes)
      response = @config.http.put "/subscriptions/#{subscription_id}", :subscription => attributes
      if response[:subscription]
        SuccessfulResult.new(:subscription => Subscription._new(@gateway, response[:subscription]))
      elsif response[:api_error_response]
         ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :subscription or :api_error_response"
      end
    end

    def self._create_signature # :nodoc:
      [
        :billing_day_of_month,
        :first_billing_date,
        :id,
        :merchant_account_id,
        :never_expires,
        :number_of_billing_cycles,
        :payment_method_token,
        :payment_method_nonce,
        :plan_id,
        :price,
        :trial_duration,
        :trial_duration_unit,
        :trial_period,
        {:options => [:do_not_inherit_add_ons_or_discounts, :start_immediately]},
        {:descriptor => [:name, :phone]}
      ] + _add_on_discount_signature
    end

    def self._update_signature # :nodoc:
      [
        :id,
        :merchant_account_id,
        :never_expires,
        :number_of_billing_cycles,
        :payment_method_token,
        :payment_method_nonce,
        :plan_id,
        :price,
        {:options => [
          :prorate_charges,
          :replace_all_add_ons_and_discounts,
          :revert_subscription_on_proration_failure
        ]},
        {:descriptor => [:name, :phone]}
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

    def _do_create(url, params) # :nodoc:
      response = @config.http.post url, params
      if response[:subscription]
        SuccessfulResult.new(:subscription => Subscription._new(@gateway, response[:subscription]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :subscription or :api_error_response"
      end
    end

    def _fetch_subscriptions(search, ids) # :nodoc:
      search.ids.in ids
      response = @config.http.post "/subscriptions/advanced_search", {:search => search.to_hash}
      attributes = response[:subscriptions]
      Util.extract_attribute_as_array(attributes, :subscription).map { |attrs| Subscription._new(@gateway, attrs) }
    end
  end
end

