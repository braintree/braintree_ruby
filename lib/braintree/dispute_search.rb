module Braintree
  class DisputeSearch < AdvancedSearch # :nodoc:
    text_fields(
      :case_number,
      :id,
      :reference_number,
      :transaction_id
    )

    multiple_value_field :kind, :allows => Dispute::Kind::All
    multiple_value_field :merchant_account_id
    multiple_value_field :reason, :allows => Dispute::Reason::All
    multiple_value_field :reason_code
    multiple_value_field :status, :allows => Dispute::Status::All

    multiple_value_field :transaction_source, :allows => [
      Transaction::Source::Api,
      Transaction::Source::ControlPanel,
      Transaction::Source::Recurring,
      Transaction::Source::Unrecognized,
    ]

    range_fields(
      :amount_disputed,
      :amount_won,
      :received_date,
      :reply_by_date
    )
  end
end
