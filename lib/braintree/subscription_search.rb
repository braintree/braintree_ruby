module Braintree
  class SubscriptionSearch < AdvancedSearch  # :nodoc:
    multiple_value_field :ids
    text_fields :id
    multiple_value_or_text_field :plan_id
    multiple_value_field :status, :allows => Subscription::Status::All
    multiple_value_field :merchant_account_id
    range_fields :price, :days_past_due, :billing_cycles_remaining
  end
end
