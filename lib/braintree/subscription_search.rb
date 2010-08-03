module Braintree
  class SubscriptionSearch < AdvancedSearch  # :nodoc:
    multiple_value_field :ids
    text_fields :days_past_due, :id
    multiple_value_or_text_field :plan_id
    multiple_value_field :status, :allows => [
      Subscription::Status::Active,
      Subscription::Status::Canceled,
      Subscription::Status::Expired,
      Subscription::Status::PastDue
    ]
    multiple_value_field :merchant_account_id
  end
end
