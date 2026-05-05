require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::LocalPaymentContextGateway do
  let(:gateway) { double(:gateway) }
  let(:graphql_client) { double(:graphql_client) }
  let(:local_payment_gateway) { Braintree::LocalPaymentContextGateway.new(gateway, graphql_client) }

  describe "#create" do
    let(:input) do
      {
        amount: {value: "10.00", currency_code: "EUR"},
        type: Braintree::LocalPaymentType::MBWAY,
        payer_info: {
          given_name: "John",
          surname: "Doe"
        }
      }
    end

    let(:response) do
      {
        data: {
          createLocalPaymentContext: {
            paymentContext: {
              id: "context-id-123",
              type: "MBWAY",
              paymentId: "payment-123",
              approvalUrl: "https://approval.url",
              merchantAccountId: "merchant-123",
              orderId: "order-456",
              createdAt: "2025-01-15T10:00:00Z",
              transactedAt: nil,
              approvedAt: nil,
              amount: {
                value: "10.00",
                currencyCode: "EUR"
              }
            }
          }
        }
      }
    end

    it "executes the createLocalPaymentContext mutation" do
      create_input = Braintree::CreateLocalPaymentContextInput.new(input)
      expect(graphql_client).to receive(:query).with(
        Braintree::LocalPaymentContextGateway::CREATE_LOCAL_PAYMENT_CONTEXT,
        {"input" => create_input.to_graphql_variables},
      ).and_return(response)

      expect(Braintree::GraphQLClient).to receive(:get_validation_errors)
        .with(response).and_return(nil)

      result = local_payment_gateway.create(create_input)
      expect(result).to be_a(Braintree::SuccessfulResult)
      expect(result.payment_context).to be_a(Braintree::LocalPaymentContext)
      expect(result.payment_context.id).to eq("context-id-123")
      expect(result.payment_context.approval_url).to eq("https://approval.url")
      expect(result.payment_context.order_id).to eq("order-456")
      expect(result.payment_context.amount.value).to eq("10.00")
      expect(result.payment_context.amount.currency_code).to eq("EUR")
    end

    it "returns an error result if there are validation errors" do
      create_input = Braintree::CreateLocalPaymentContextInput.new(input)
      errors = {:errors =>
        [ {:attribute => "", :code => "123", :message => "Invalid amount"} ]}

      expect(graphql_client).to receive(:query).and_return(response)
      expect(Braintree::GraphQLClient).to receive(:get_validation_errors)
        .with(response).and_return(errors)

      result = local_payment_gateway.create(create_input)
      expect(result).to be_a(Braintree::ErrorResult)
      expect(result.errors.first.message).to eq("Invalid amount")
    end

    it "raises an UnexpectedError if response is malformed" do
      create_input = Braintree::CreateLocalPaymentContextInput.new(input)
      bad_response = {:data => {}}

      expect(graphql_client).to receive(:query).and_return(bad_response)
      expect(Braintree::GraphQLClient).to receive(:get_validation_errors)
        .with(bad_response).and_return(nil)

      expect {
        local_payment_gateway.create(create_input)
      }.to raise_error(Braintree::UnexpectedError)
    end
  end

  describe "#find" do
    let(:find_response) do
      {
        data: {
          node: {
            id: "context-id-123",
            legacyId: "legacy-123",
            type: "MBWAY",
            paymentId: "payment-123",
            orderId: "order-456",
            approvalUrl: "https://approval.url",
            merchantAccountId: "merchant-123",
            createdAt: "2025-01-15T10:00:00Z",
            updatedAt: "2025-01-15T10:05:00Z",
            transactedAt: nil,
            approvedAt: nil,
            expiredAt: nil,
            amount: {
              value: "10.00",
              currencyIsoCode: "EUR"
            }
          }
        }
      }
    end

    it "finds a payment context by ID" do
      expect(graphql_client).to receive(:query).with(
        Braintree::LocalPaymentContextGateway::FIND_LOCAL_PAYMENT_CONTEXT,
        {"id" => "context-id-123"},
      ).and_return(find_response)

      expect(Braintree::GraphQLClient).to receive(:get_validation_errors)
        .with(find_response).and_return(nil)

      result = local_payment_gateway.find("context-id-123")
      expect(result).to be_a(Braintree::SuccessfulResult)
      expect(result.payment_context).to be_a(Braintree::LocalPaymentContext)
      expect(result.payment_context.id).to eq("context-id-123")
      expect(result.payment_context.legacy_id).to eq("legacy-123")
      expect(result.payment_context.type).to eq("MBWAY")
      expect(result.payment_context.order_id).to eq("order-456")
      expect(result.payment_context.updated_at).to eq("2025-01-15T10:05:00Z")
    end

    it "raises NotFoundError when payment context does not exist" do
      not_found_response = {data: {node: nil}}

      expect(graphql_client).to receive(:query).and_return(not_found_response)
      expect(Braintree::GraphQLClient).to receive(:get_validation_errors)
        .with(not_found_response).and_return(nil)

      expect {
        local_payment_gateway.find("non-existent-id")
      }.to raise_error(Braintree::NotFoundError, "Payment context not found")
    end
  end
end
