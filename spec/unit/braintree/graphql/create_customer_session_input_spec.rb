require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")


describe Braintree::CreateCustomerSessionInput do
  let(:input_data) do
  {
    merchant_account_id: "merchant-account-id",
    session_id: "session-id",
    customer: {
      email: "test@example.com" ,
    },
    domain: "example.com",
    purchase_units: [
      {
        amount: {
          value: "100.00",
          currency_code: "USD"
        },
        payee: {
          email_address: "merchant@example.com",
          client_id: "client-123"
        }
      }
    ]
  }
  end

  describe "#initialize" do
    it "initializes with attributes" do
      input = Braintree::CreateCustomerSessionInput.new(input_data)

      expect(input.attrs).to eq(input_data.keys)
      expect(input.merchant_account_id).to eq("merchant-account-id")
      expect(input.session_id).to eq("session-id")
      expect(input.customer).to be_a(Braintree::CustomerSessionInput)
      expect(input.customer.email).to eq("test@example.com")
      expect(input.domain).to eq("example.com")
      expect(input.purchase_units).to be_a(Array)
      expect(input.purchase_units.first).to be_a(Braintree::PayPalPurchaseUnitInput)
      expect(input.purchase_units.first.amount.value).to eq("100.00")
      expect(input.purchase_units.first.payee.email_address).to eq("merchant@example.com")
    end

    it "handles nil customer" do
      attributes = {merchant_account_id: "merchant-account-id"}
      input = Braintree::CreateCustomerSessionInput.new(attributes)
      expect(input.customer).to be_nil
    end
  end


  describe "#inspect" do
      it "returns a string representation of the object" do
        input = Braintree::CreateCustomerSessionInput.new(input_data)
        expected_string = "#<Braintree::CreateCustomerSessionInput merchant_account_id:\"merchant-account-id\" session_id:\"session-id\" customer:#<Braintree::CustomerSessionInput email:\"test@example.com\"> domain:\"example.com\" purchase_units:[#<Braintree::PayPalPurchaseUnitInput amount:#<Braintree::MonetaryAmountInput value:\"100.00\" currency_code:\"USD\"> payee:#<Braintree::PayPalPayeeInput email_address:\"merchant@example.com\" client_id:\"client-123\">>]>"
        expect(input.inspect).to eq(expected_string)
      end

      it "handles nil values" do
        attributes = {
          merchant_account_id: "merchant-account-id",
          session_id: nil,
          customer: nil
        }
        input = Braintree::CreateCustomerSessionInput.new(attributes)
        expected_string = "#<Braintree::CreateCustomerSessionInput merchant_account_id:\"merchant-account-id\" session_id:nil customer:nil>"

        expect(input.inspect).to eq(expected_string)
      end

  end

  describe "#to_graphql_variables" do
    it "converts the input to graphql variables" do
      input = Braintree::CreateCustomerSessionInput.new(input_data)
      expected_variables = {
        "merchantAccountId" => "merchant-account-id",
        "sessionId" => "session-id",
        "domain" => "example.com",
        "customer" => {"email" => "test@example.com"},
        "purchaseUnits" => [
          {
            "amount" => {"value" => "100.00", "currencyCode" => "USD"},
            "payee" => {"emailAddress" => "merchant@example.com", "clientId" => "client-123"}
          }
        ]
      }

      expect(input.to_graphql_variables).to eq(expected_variables)


    end

    it "handles nil values" do
        attributes = {merchant_account_id: "merchant-account-id"}
        input = Braintree::CreateCustomerSessionInput.new(attributes)
        expected_variables = {"merchantAccountId" => "merchant-account-id"}

        expect(input.to_graphql_variables).to eq(expected_variables)
    end
  end
end