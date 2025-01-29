require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")


describe Braintree::UpdateCustomerSessionInput do
  let(:input_data) do
  {
    merchant_account_id: "merchant-account-id",
    session_id: "session-id",
    customer: {email: "test@example.com"}
  }
  end
  describe "#initialize" do
    it "initializes with attributes" do
      input = Braintree::UpdateCustomerSessionInput.new(input_data)

      expect(input.attrs).to eq(input_data.keys)
      expect(input.merchant_account_id).to eq("merchant-account-id")
      expect(input.session_id).to eq("session-id")
      expect(input.customer).to be_a(Braintree::CustomerSessionInput)
      expect(input.customer.email).to eq("test@example.com")
    end

    it "disallows nil session id" do
      attributes = {
        merchant_account_id: "merchant-account-id",
      }
      expect do
        Braintree::UpdateCustomerSessionInput.new(attributes)
      end.to raise_error(ArgumentError, "Expected hash to contain a :session_id")
    end

    it "handles nil customer" do
      attributes = {
        merchant_account_id: "merchant-account-id",
        session_id: "session-id",
      }
      input = Braintree::UpdateCustomerSessionInput.new(attributes)

      expect(input.customer).to be_nil
    end
  end


  describe "#inspect" do
      it "returns a string representation of the object" do
        input = Braintree::UpdateCustomerSessionInput.new(input_data)
        expected_string = "#<Braintree::UpdateCustomerSessionInput merchant_account_id:\"merchant-account-id\" session_id:\"session-id\" customer:#<Braintree::CustomerSessionInput email:\"test@example.com\">>"
        expect(input.inspect).to eq(expected_string)

      end

      it "handles nil values" do
        attributes = {
          merchant_account_id: "merchant-account-id",
          session_id: "session-id",
        }
        input = Braintree::UpdateCustomerSessionInput.new(attributes)
        expected_string = "#<Braintree::UpdateCustomerSessionInput merchant_account_id:\"merchant-account-id\" session_id:\"session-id\">"

        expect(input.inspect).to eq(expected_string)
      end

  end

  describe "#to_graphql_variables" do
    it "converts the input to graphql variables" do
      input = Braintree::UpdateCustomerSessionInput.new(input_data)
      expected_variables = {
        "merchantAccountId" => "merchant-account-id",
        "sessionId" => "session-id",
        "customer" => {"email" => "test@example.com"},
      }

      expect(input.to_graphql_variables).to eq(expected_variables)
    end

    it "handles nil values" do
      attributes = {
        merchant_account_id: "merchant-account-id",
        session_id: "session-id",
      }
      input = Braintree::UpdateCustomerSessionInput.new(attributes)

      expected_variables = {
        "merchantAccountId" => "merchant-account-id",
        "sessionId" => "session-id",
      }

      expect(input.to_graphql_variables).to eq(expected_variables)
    end
  end

end
