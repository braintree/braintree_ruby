module Braintree
  class CustomerSearch < AdvancedSearch # :nodoc:
    text_fields(
      :address_extended_address,
      :address_first_name,
      :address_last_name,
      :address_locality,
      :address_postal_code,
      :address_region,
      :address_street_address,
      :cardholder_name,
      :company,
      :email,
      :fax,
      :first_name,
      :id,
      :last_name,
      :payment_method_token,
      :phone,
      :website
    )

    equality_fields :credit_card_expiration_date

    partial_match_fields :credit_card_number

    multiple_value_field :ids

    range_fields :created_at
  end
end
