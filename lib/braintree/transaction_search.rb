module Braintree
  class TransactionSearch < AdvancedSearch # :nodoc:
    text_fields(
      :billing_company,
      :billing_country_name,
      :billing_extended_address,
      :billing_first_name,
      :billing_last_name,
      :billing_locality,
      :billing_postal_code,
      :billing_region,
      :billing_street_address,
      :credit_card_cardholder_name,
      :currency,
      :customer_company,
      :customer_email,
      :customer_fax,
      :customer_first_name,
      :customer_id,
      :customer_last_name,
      :customer_phone,
      :customer_website,
      :id,
      :order_id,
      :payment_method_token,
      :processor_authorization_code,
      :settlement_batch_id,
      :shipping_company,
      :shipping_country_name,
      :shipping_extended_address,
      :shipping_first_name,
      :shipping_last_name,
      :shipping_locality,
      :shipping_postal_code,
      :shipping_region,
      :shipping_street_address
    )

    equality_fields :credit_card_expiration_date
    partial_match_fields :credit_card_number

    multiple_value_field :created_using, :allows => [
      Transaction::CreatedUsing::FullInformation,
      Transaction::CreatedUsing::Token
    ]
    multiple_value_field :credit_card_card_type, :allows => CreditCard::CardType::All
    multiple_value_field :credit_card_customer_location, :allows => [
      CreditCard::CustomerLocation::International,
      CreditCard::CustomerLocation::US
    ]
    multiple_value_field :ids
    multiple_value_field :merchant_account_id
    multiple_value_field :status, :allows => Transaction::Status::All
    multiple_value_field :source, :allows => [
      Transaction::Source::Api,
      Transaction::Source::ControlPanel,
      Transaction::Source::Recurring
    ]
    multiple_value_field :type

    key_value_fields :refund

    range_fields :amount, :created_at, :authorized_at, :failed_at, :gateway_rejected_at, :processor_declined_at,
                 :settled_at, :submitted_for_settlement_at, :voided_at
  end
end
