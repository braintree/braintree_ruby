module Braintree
  class SubscriptionSearch < AdvancedSearch
    multiple_value_field :ids
    search_fields :plan_id, :days_past_due
    multiple_value_field :status, :allows => [
      Subscription::Status::Active,
      Subscription::Status::Canceled,
      Subscription::Status::PastDue
    ]
  end
end
