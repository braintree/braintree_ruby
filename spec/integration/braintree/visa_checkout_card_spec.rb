require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::VisaCheckoutCard do
  it "can create from payment method nonce" do
    customer = Braintree::Customer.create!

    result = Braintree::PaymentMethod.create(
      :payment_method_nonce => Braintree::Test::Nonce::VisaCheckoutDiscover,
      :customer_id => customer.id,
    )
    expect(result).to be_success

    visa_checkout_card = result.payment_method
    expect(visa_checkout_card).to be_a(Braintree::VisaCheckoutCard)
    expect(visa_checkout_card.call_id).to eq("abc123")
    expect(visa_checkout_card.billing_address).not_to be_nil
    expect(visa_checkout_card.bin).not_to be_nil
    expect(visa_checkout_card.card_type).not_to be_nil
    expect(visa_checkout_card.cardholder_name).not_to be_nil
    expect(visa_checkout_card.commercial).not_to be_nil
    expect(visa_checkout_card.country_of_issuance).not_to be_nil
    expect(visa_checkout_card.created_at).not_to be_nil
    expect(visa_checkout_card.customer_id).not_to be_nil
    expect(visa_checkout_card.customer_location).not_to be_nil
    expect(visa_checkout_card.debit).not_to be_nil
    expect(visa_checkout_card.default?).not_to be_nil
    expect(visa_checkout_card.durbin_regulated).not_to be_nil
    expect(visa_checkout_card.expiration_date).not_to be_nil
    expect(visa_checkout_card.expiration_month).not_to be_nil
    expect(visa_checkout_card.expiration_year).not_to be_nil
    expect(visa_checkout_card.expired?).not_to be_nil
    expect(visa_checkout_card.healthcare).not_to be_nil
    expect(visa_checkout_card.image_url).not_to be_nil
    expect(visa_checkout_card.issuing_bank).not_to be_nil
    expect(visa_checkout_card.last_4).not_to be_nil
    expect(visa_checkout_card.payroll).not_to be_nil
    expect(visa_checkout_card.prepaid).not_to be_nil
    expect(visa_checkout_card.product_id).not_to be_nil
    expect(visa_checkout_card.subscriptions).not_to be_nil
    expect(visa_checkout_card.token).not_to be_nil
    expect(visa_checkout_card.unique_number_identifier).not_to be_nil
    expect(visa_checkout_card.updated_at).not_to be_nil

    customer = Braintree::Customer.find(customer.id)
    expect(customer.visa_checkout_cards.size).to eq(1)
    expect(customer.visa_checkout_cards.first).to eq(visa_checkout_card)
  end

  it "can create with verification" do
    customer = Braintree::Customer.create!

    result = Braintree::PaymentMethod.create(
      :payment_method_nonce => Braintree::Test::Nonce::VisaCheckoutDiscover,
      :customer_id => customer.id,
      :options => {:verify_card => true},
    )
    expect(result).to be_success
    expect(result.payment_method.verification.status).to eq(Braintree::CreditCardVerification::Status::Verified)
  end

  it "can search for transactions" do
    transaction_create_result = Braintree::Transaction.sale(
      :payment_method_nonce => Braintree::Test::Nonce::VisaCheckoutDiscover,
      :amount => "47.00",
    )
    expect(transaction_create_result).to be_success
    transaction_id = transaction_create_result.transaction.id

    search_results = Braintree::Transaction.search do |search|
      search.id.is transaction_id
      search.payment_instrument_type.is Braintree::PaymentInstrumentType::VisaCheckoutCard
    end
    expect(search_results.first.id).to eq(transaction_id)
  end

  it "can create transaction from nonce and vault" do
    customer = Braintree::Customer.create!

    result = Braintree::Transaction.sale(
      :payment_method_nonce => Braintree::Test::Nonce::VisaCheckoutDiscover,
      :customer_id => customer.id,
      :amount => "47.00",
      :options => {:store_in_vault => true},
    )
    expect(result).to be_success

    visa_checkout_card_details = result.transaction.visa_checkout_card_details
    expect(visa_checkout_card_details.call_id).to eq("abc123")
    expect(visa_checkout_card_details.bin).not_to be_nil
    expect(visa_checkout_card_details.card_type).not_to be_nil
    expect(visa_checkout_card_details.cardholder_name).not_to be_nil
    expect(visa_checkout_card_details.commercial).not_to be_nil
    expect(visa_checkout_card_details.country_of_issuance).not_to be_nil
    expect(visa_checkout_card_details.customer_location).not_to be_nil
    expect(visa_checkout_card_details.debit).not_to be_nil
    expect(visa_checkout_card_details.durbin_regulated).not_to be_nil
    expect(visa_checkout_card_details.expiration_date).not_to be_nil
    expect(visa_checkout_card_details.expiration_month).not_to be_nil
    expect(visa_checkout_card_details.expiration_year).not_to be_nil
    expect(visa_checkout_card_details.healthcare).not_to be_nil
    expect(visa_checkout_card_details.image_url).not_to be_nil
    expect(visa_checkout_card_details.issuing_bank).not_to be_nil
    expect(visa_checkout_card_details.last_4).not_to be_nil
    expect(visa_checkout_card_details.payroll).not_to be_nil
    expect(visa_checkout_card_details.prepaid).not_to be_nil
    expect(visa_checkout_card_details.product_id).not_to be_nil
    expect(visa_checkout_card_details.token).not_to be_nil
  end
end
