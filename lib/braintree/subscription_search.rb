module Braintree
  class SubscriptionSearch < AdvancedSearch
    search_fields :plan_id
    multiple_value_field :status
  end
end
