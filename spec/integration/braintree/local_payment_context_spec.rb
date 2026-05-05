require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::LocalPaymentContextGateway do
  before(:each) { skip("Pending until test data is fixed.") }
  let(:gateway) do
    Braintree::Gateway.new(
      :environment => :development,
      :merchant_id => "pwpp_multi_account_merchant",
      :public_key => "pwpp_multi_account_merchant_public_key",
      :private_key => "pwpp_multi_account_merchant_private_key",
    )
  end

  describe "create" do
    it "can create MBWAY payment context" do
      input = Braintree::CreateLocalPaymentContextInput.new(
        amount: {
          value: "10.00",
          currency_code: "EUR"
        },
        type: Braintree::LocalPaymentType::MBWAY,
        payer_info: {
          given_name: "John",
          surname: "Doe",
          phone_number: "912345678",
          phone_country_code: "351"
        },
        shipping_address: {
          street_address: "123 Main St",
          extended_address: "Apt 4B",
          locality: "Lisbon",
          region: "Lisboa",
          postal_code: "1000-001",
          country_code: "PT"
        },
        return_url: "https://example.com/return",
        cancel_url: "https://example.com/cancel",
        merchant_account_id: "eur_pwpp_multi_account_merchant_account",
      )

      result = gateway.local_payment_context.create(input)

      expect(result.success?).to eq(true)
      expect(result.payment_context).not_to be_nil
      expect(result.payment_context.id).not_to be_nil
      expect(result.payment_context.legacy_id).not_to be_nil
      expect(result.payment_context.type).to eq("MBWAY")
      expect(result.payment_context.amount.value).to eq("10.00")
      expect(result.payment_context.amount.currency_code).to eq("EUR")
    end

    it "can create CRYPTO payment context" do
      input = Braintree::CreateLocalPaymentContextInput.new(
        amount: {
          value: "25.00",
          currency_code: "USD"
        },
        type: Braintree::LocalPaymentType::CRYPTO,
        payer_info: {
          given_name: "John",
          surname: "Doe",
          email: "john.doe@example.com"
        },
        return_url: "https://example.com/return",
        cancel_url: "https://example.com/cancel",
        merchant_account_id: "usd_pwpp_multi_account_merchant_account",
      )

      result = gateway.local_payment_context.create(input)

      expect(result.success?).to eq(true)
      expect(result.payment_context).not_to be_nil
      expect(result.payment_context.id).not_to be_nil
      expect(result.payment_context.legacy_id).not_to be_nil
      expect(result.payment_context.type).to eq("CRYPTO")
      expect(result.payment_context.amount.value).to eq("25.00")
      expect(result.payment_context.amount.currency_code).to eq("USD")
    end

    it "can create payment context with only required fields" do
      input = Braintree::CreateLocalPaymentContextInput.new(
        amount: {
          value: "15.00",
          currency_code: "USD"
        },
        type: Braintree::LocalPaymentType::CRYPTO,
        payer_info: {
          given_name: "Jane",
          surname: "Smith"
        },
        return_url: "https://example.com/return",
        cancel_url: "https://example.com/cancel",
      )

      result = gateway.local_payment_context.create(input)

      expect(result.success?).to eq(true)
      expect(result.payment_context).not_to be_nil
      expect(result.payment_context.id).not_to be_nil
      expect(result.payment_context.legacy_id).not_to be_nil
      expect(result.payment_context.type).to eq("CRYPTO")
      expect(result.payment_context.amount.value).to eq("15.00")
      expect(result.payment_context.amount.currency_code).to eq("USD")
    end

    it "returns error for invalid input" do
      input = Braintree::CreateLocalPaymentContextInput.new(
        amount: {
          value: "invalid",
          currency_code: "EUR"
        },
        type: Braintree::LocalPaymentType::MBWAY,
        payer_info: {
          given_name: "John",
          surname: "Doe"
        },
        return_url: "https://example.com/return",
        cancel_url: "https://example.com/cancel",
        merchant_account_id: "eur_pwpp_multi_account_merchant_account",
      )

      result = gateway.local_payment_context.create(input)

      expect(result.success?).to eq(false)
      expect(result.errors.size).to be > 0
    end
  end

  describe "find" do
    it "can find a payment context by ID" do
      input = Braintree::CreateLocalPaymentContextInput.new(
        amount: {
          value: "10.00",
          currency_code: "EUR"
        },
        type: Braintree::LocalPaymentType::MBWAY,
        payer_info: {
          given_name: "John",
          surname: "Doe",
          phone_number: "912345678",
          phone_country_code: "351"
        },
        return_url: "https://example.com/return",
        cancel_url: "https://example.com/cancel",
        merchant_account_id: "eur_pwpp_multi_account_merchant_account",
      )

      create_result = gateway.local_payment_context.create(input)
      expect(create_result.success?).to eq(true)

      payment_context_id = create_result.payment_context.id
      find_result = gateway.local_payment_context.find(payment_context_id)

      expect(find_result.success?).to eq(true)
      expect(find_result.payment_context).not_to be_nil
      expect(find_result.payment_context.id).to eq(payment_context_id)
      expect(find_result.payment_context.legacy_id).not_to be_nil
      expect(find_result.payment_context.type).to eq("MBWAY")
    end

    it "raises NotFoundError for non-existent ID" do
      expect {
        gateway.local_payment_context.find("non-existent-id-123")
      }.to raise_error(Braintree::NotFoundError)
    end
  end
end
