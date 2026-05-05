require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::LocalPaymentContext do
  describe "#initialize" do
    it "initializes from response hash" do
      response = {
        response: {
          "paymentContext" => {
            "id" => "context-123",
            "legacyId" => "legacy-456",
            "type" => "MBWAY",
            "paymentId" => "payment-789",
            "orderId" => "order-abc",
            "approvalUrl" => "https://example.com/approve",
            "merchantAccountId" => "merchant-xyz",
            "createdAt" => "2025-01-15T10:00:00Z",
            "updatedAt" => "2025-01-15T11:00:00Z",
            "transactedAt" => "2025-01-15T12:00:00Z",
            "approvedAt" => "2025-01-15T11:30:00Z",
            "expiredAt" => nil,
            "amount" => {
              "value" => "10.00",
              "currencyCode" => "EUR"
            }
          }
        }
      }

      context = Braintree::LocalPaymentContext._new(response)

      expect(context.id).to eq("context-123")
      expect(context.legacy_id).to eq("legacy-456")
      expect(context.type).to eq("MBWAY")
      expect(context.payment_id).to eq("payment-789")
      expect(context.order_id).to eq("order-abc")
      expect(context.approval_url).to eq("https://example.com/approve")
      expect(context.merchant_account_id).to eq("merchant-xyz")
      expect(context.created_at).to eq("2025-01-15T10:00:00Z")
      expect(context.updated_at).to eq("2025-01-15T11:00:00Z")
      expect(context.transacted_at).to eq("2025-01-15T12:00:00Z")
      expect(context.approved_at).to eq("2025-01-15T11:30:00Z")
      expect(context.expired_at).to be_nil
      expect(context.amount).to be_a(Braintree::MonetaryAmount)
      expect(context.amount.value).to eq("10.00")
      expect(context.amount.currency_code).to eq("EUR")
    end

    it "initializes from attributes hash" do
      attributes = {
        id: "context-123",
        type: "OXXO",
        approval_url: "https://example.com/approve"
      }

      context = Braintree::LocalPaymentContext._new(attributes)

      expect(context.id).to eq("context-123")
      expect(context.type).to eq("OXXO")
      expect(context.approval_url).to eq("https://example.com/approve")
    end

    it "handles symbol keys in amount hash" do
      response = {
        response: {
          paymentContext: {
            id: "context-123",
            type: "MBWAY",
            amount: {
              value: "15.00",
              currencyCode: "USD"
            }
          }
        }
      }

      context = Braintree::LocalPaymentContext._new(response)

      expect(context.amount.value).to eq("15.00")
      expect(context.amount.currency_code).to eq("USD")
    end

    it "handles currencyIsoCode in amount hash" do
      response = {
        response: {
          paymentContext: {
            id: "context-123",
            type: "MBWAY",
            amount: {
              value: "20.00",
              currencyIsoCode: "GBP"
            }
          }
        }
      }

      context = Braintree::LocalPaymentContext._new(response)

      expect(context.amount.currency_code).to eq("GBP")
    end

    it "returns nil for amount when not present" do
      response = {
        response: {
          paymentContext: {
            id: "context-123",
            type: "MBWAY"
          }
        }
      }

      context = Braintree::LocalPaymentContext._new(response)

      expect(context.amount).to be_nil
    end
  end

  describe "#inspect" do
    it "returns formatted string representation" do
      attributes = {
        id: "context-123",
        type: "OXXO",
        approval_url: "https://example.com/approve"
      }

      context = Braintree::LocalPaymentContext._new(attributes)

      expect(context.inspect).to include("LocalPaymentContext")
      expect(context.inspect).to include("id:")
      expect(context.inspect).to include("type:")
      expect(context.inspect).to include("approval_url:")
    end
  end

  describe "self.new" do
    it "is protected" do
      expect do
        Braintree::LocalPaymentContext.new
      end.to raise_error(NoMethodError, /protected method .new/)
    end
  end
end
