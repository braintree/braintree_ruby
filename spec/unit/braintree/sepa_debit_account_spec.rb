require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::SepaDirectDebitAccount do
  describe "self.new" do
    subject do
      -> { described_class.new }
    end

    it "is protected" do
      is_expected.to raise_error(NoMethodError, /protected method .new/)
    end
  end

  describe "self._new" do
    let(:params) do
      {
        bank_reference_token: "a-reference-token",
        created_at: Time.now,
        customer_global_id: "a-customer-global-id",
        customer_id: "a-customer-id",
        default: true,
        global_id: "a-global-id",
        image_url: "a-image-url",
        last_4: "4321",
        mandate_type: "ONE_OFF",
        merchant_or_partner_customer_id: "a-mp-customer-id",
        subscriptions: [{price: "10.00"}],
        token: "a-token",
        updated_at: Time.now,
        view_mandate_url: "a-view-mandate-url",
      }
    end

    subject do
      described_class._new(:gateway, params)
    end

    it "initializes the object with the appropriate attributes set" do
      is_expected.to have_attributes(**params)
    end
  end

  describe "self.find" do
    let(:token) { "token" }

    subject do
      described_class.find(token)
    end

    it "calls gateway find" do
      expect_any_instance_of(Braintree::SepaDirectDebitAccountGateway).to receive(:find).with(token)
      subject
    end
  end

  describe "self.delete" do
    let(:token) { "token" }

    subject do
      described_class.delete(token)
    end

    it "calls gateway delete" do
      expect_any_instance_of(Braintree::SepaDirectDebitAccountGateway).to receive(:delete).with(token)
      subject
    end
  end

  describe "default?" do
    subject do
      described_class._new(:gateway, :default => default).default?
    end

    context "when sepa debit account is the default payment method for the customer" do
      let(:default) { true }

      it { is_expected.to be true }
    end

    context "when sepa debit account is not the default payment method for the customer" do
      let(:default) { false }

      it { is_expected.to be false }
    end
  end
end
