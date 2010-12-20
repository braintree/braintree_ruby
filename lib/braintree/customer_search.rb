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
      :company,
      :credit_card_expiration_date,
      :email,
      :fax,
      :first_name,
      :last_name,
      :payment_method_token,
      :phone,
      :website
    )

    multiple_value_field :ids

    range_fields :created_at
  end
end
