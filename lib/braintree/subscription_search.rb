module Braintree
  class SubscriptionSearch < AdvancedSearch
    search_fields :plan_id
    multiple_value_field :status, :allows => [
      Subscription::Status::Active,
      Subscription::Status::Canceled,
      Subscription::Status::PastDue
    ]
  end
end
