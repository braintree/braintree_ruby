require File.expand_path(File.dirname(__FILE__) + "/../../../spec_helper")

describe Braintree::CreateLocalPaymentContextInput do
  let(:input_data) do
    {
      amount: {value: "10.00", currency_code: "EUR"},
      type: Braintree::LocalPaymentType::MBWAY,
      payer_info: {
        given_name: "John",
        surname: "Doe"
      },
      order_id: "order-123"
    }
  end

  describe "#initialize" do
    it "initializes with attributes" do
      input = Braintree::CreateLocalPaymentContextInput.new(input_data)

      expect(input.attrs).to eq(input_data.keys)
      expect(input.type).to eq(Braintree::LocalPaymentType::MBWAY)
      expect(input.order_id).to eq("order-123")
      expect(input.amount).to be_a(Braintree::MonetaryAmountInput)
      expect(input.payer_info).to be_a(Braintree::PayerInfoInput)
    end

    it "handles nil payer_info" do
      attributes = {amount: {value: "10.00", currency_code: "EUR"}, type: "OXXO"}
      input = Braintree::CreateLocalPaymentContextInput.new(attributes)
      expect(input.payer_info).to be_nil
    end
  end

  describe "#to_graphql_variables" do
    it "converts to graphql variables with camelCase keys" do
      input = Braintree::CreateLocalPaymentContextInput.new(input_data)
      expected_variables = {
        "paymentContext" => {
          "amount" => {"value" => "10.00", "currencyCode" => "EUR"},
          "orderId" => "order-123",
          "payerInfo" => {
            "givenName" => "John",
            "surname" => "Doe"
          },
          "type" => Braintree::LocalPaymentType::MBWAY
        }
      }

      expect(input.to_graphql_variables).to eq(expected_variables)
    end
  end

  describe "#inspect" do
    it "returns formatted string" do
      input = Braintree::CreateLocalPaymentContextInput.new(input_data)
      result = input.inspect

      expect(result).to include("CreateLocalPaymentContextInput")
      expect(result).to include("amount:")
      expect(result).to include("type:")
    end
  end
end
