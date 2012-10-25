module Braintree
  class CreditCardVerificationSearch < AdvancedSearch # :nodoc:
     text_fields(
       :id,
       :credit_card_cardholder_name
     )

    equality_fields :credit_card_expiration_date
    partial_match_fields :credit_card_number

    multiple_value_field :credit_card_card_type, :allows => CreditCard::CardType::All
    multiple_value_field :ids
    range_fields :created_at
  end
end
