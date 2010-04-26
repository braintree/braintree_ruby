module Braintree
  class TransactionSearch < AdvancedSearch
    search_fields(
      :billing_company,
      :billing_country_name,
      :billing_extended_address,
      :billing_first_name,
      :billing_last_name,
      :billing_locality,
      :billing_postal_code,
      :billing_region,
      :billing_street_address,
      :credit_card_number,
      :credit_card_cardholder_name,
      :credit_card_number,
      :currency,
      :customer_id,
      :customer_company,
      :customer_email,
      :customer_fax,
      :customer_first_name,
      :customer_last_name,
      :customer_phone,
      :customer_website
    )
  end
end
