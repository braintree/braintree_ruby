require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::SamsungPayCard do
  it "can create from payment method nonce" do
    customer = Braintree::Customer.create!

    result = Braintree::PaymentMethod.create(
      :payment_method_nonce => Braintree::Test::Nonce::SamsungPayDiscover,
      :customer_id => customer.id,
      :cardholder_name => "Jenny Block",
      :billing_address => {
          :first_name => "New First Name",
          :last_name => "New Last Name",
          :company => "New Company",
          :street_address => "123 New St",
          :extended_address => "Apt New",
          :locality => "New City",
          :region => "New State",
          :postal_code => "56789",
          :country_name => "United States of America"
      },
    )
    expect(result).to be_success

    samsung_pay_card = result.payment_method
    expect(samsung_pay_card).to be_a(Braintree::SamsungPayCard)
    expect(samsung_pay_card.billing_address).not_to be_nil
    expect(samsung_pay_card.bin).not_to be_nil
    expect(samsung_pay_card.cardholder_name).not_to be_nil
    expect(samsung_pay_card.card_type).not_to be_nil
    expect(samsung_pay_card.commercial).not_to be_nil
    expect(samsung_pay_card.country_of_issuance).not_to be_nil
    expect(samsung_pay_card.created_at).not_to be_nil
    expect(samsung_pay_card.customer_id).not_to be_nil
    expect(samsung_pay_card.customer_location).not_to be_nil
    expect(samsung_pay_card.debit).not_to be_nil
    expect(samsung_pay_card.default?).not_to be_nil
    expect(samsung_pay_card.durbin_regulated).not_to be_nil
    expect(samsung_pay_card.expiration_date).not_to be_nil
    expect(samsung_pay_card.expiration_month).not_to be_nil
    expect(samsung_pay_card.expiration_year).not_to be_nil
    expect(samsung_pay_card.expired?).not_to be_nil
    expect(samsung_pay_card.healthcare).not_to be_nil
    expect(samsung_pay_card.image_url).not_to be_nil
    expect(samsung_pay_card.issuing_bank).not_to be_nil
    expect(samsung_pay_card.last_4).not_to be_nil
    expect(samsung_pay_card.payroll).not_to be_nil
    expect(samsung_pay_card.prepaid).not_to be_nil
    expect(samsung_pay_card.product_id).not_to be_nil
    expect(samsung_pay_card.source_card_last_4).not_to be_nil
    expect(samsung_pay_card.subscriptions).not_to be_nil
    expect(samsung_pay_card.token).not_to be_nil
    expect(samsung_pay_card.unique_number_identifier).not_to be_nil
    expect(samsung_pay_card.updated_at).not_to be_nil

    customer = Braintree::Customer.find(customer.id)
    expect(customer.samsung_pay_cards.size).to eq(1)
    expect(customer.samsung_pay_cards.first).to eq(samsung_pay_card)
  end

  it "returns cardholder_name and billing_address" do
    customer = Braintree::Customer.create!

    result = Braintree::PaymentMethod.create(
      :payment_method_nonce => Braintree::Test::Nonce::SamsungPayDiscover,
      :customer_id => customer.id,
      :cardholder_name => "Jenny Block",
      :billing_address => {
          :first_name => "New First Name",
          :last_name => "New Last Name",
          :company => "New Company",
          :street_address => "123 New St",
          :extended_address => "Apt New",
          :locality => "New City",
          :region => "New State",
          :postal_code => "56789",
          :country_name => "United States of America"
      },
    )

    expect(result).to be_success
    expect(result.payment_method.cardholder_name).to eq("Jenny Block")

    address = result.payment_method.billing_address
    expect(address.first_name).to eq("New First Name")
    expect(address.last_name).to eq("New Last Name")
    expect(address.company).to eq("New Company")
    expect(address.street_address).to eq("123 New St")
    expect(address.extended_address).to eq("Apt New")
    expect(address.locality).to eq("New City")
    expect(address.region).to eq("New State")
    expect(address.postal_code).to eq("56789")
  end

  it "can search for transactions" do
    transaction_create_result = Braintree::Transaction.sale(
      :payment_method_nonce => Braintree::Test::Nonce::SamsungPayDiscover,
      :amount => "47.00",
    )
    expect(transaction_create_result).to be_success
    transaction_id = transaction_create_result.transaction.id

    search_results = Braintree::Transaction.search do |search|
      search.id.is transaction_id
      search.payment_instrument_type.is Braintree::PaymentInstrumentType::SamsungPayCard
    end
    expect(search_results.first.id).to eq(transaction_id)
  end

  it "can create transaction from nonce and vault" do
    customer = Braintree::Customer.create!

    result = Braintree::Transaction.sale(
      :payment_method_nonce => Braintree::Test::Nonce::SamsungPayDiscover,
      :customer_id => customer.id,
      :amount => "47.00",
      :options => {:store_in_vault => true},
    )
    expect(result).to be_success

    samsung_pay_card_details = result.transaction.samsung_pay_card_details
    expect(samsung_pay_card_details.bin).not_to be_nil
    expect(samsung_pay_card_details.card_type).not_to be_nil
    expect(samsung_pay_card_details.commercial).not_to be_nil
    expect(samsung_pay_card_details.country_of_issuance).not_to be_nil
    expect(samsung_pay_card_details.customer_location).not_to be_nil
    expect(samsung_pay_card_details.debit).not_to be_nil
    expect(samsung_pay_card_details.durbin_regulated).not_to be_nil
    expect(samsung_pay_card_details.expiration_date).not_to be_nil
    expect(samsung_pay_card_details.expiration_month).not_to be_nil
    expect(samsung_pay_card_details.expiration_year).not_to be_nil
    expect(samsung_pay_card_details.healthcare).not_to be_nil
    expect(samsung_pay_card_details.image_url).not_to be_nil
    expect(samsung_pay_card_details.issuing_bank).not_to be_nil
    expect(samsung_pay_card_details.last_4).not_to be_nil
    expect(samsung_pay_card_details.payroll).not_to be_nil
    expect(samsung_pay_card_details.prepaid).not_to be_nil
    expect(samsung_pay_card_details.product_id).not_to be_nil
    expect(samsung_pay_card_details.source_card_last_4).not_to be_nil
    expect(samsung_pay_card_details.source_card_last_4).to eq("3333")
    expect(samsung_pay_card_details.token).not_to be_nil
  end
end
