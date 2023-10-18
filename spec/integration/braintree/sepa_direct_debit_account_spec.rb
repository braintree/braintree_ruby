require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::SepaDirectDebitAccount do
  before do
    Braintree::Configuration.merchant_id = "integration_merchant_id"
    Braintree::Configuration.public_key = "integration_public_key"
    Braintree::Configuration.private_key = "integration_private_key"
  end

  let(:customer) { Braintree::Customer.create.customer }
  let(:nonce) { Braintree::Test::Nonce::SepaDirectDebit }

  let(:token) do
    Braintree::PaymentMethod.create(
      payment_method_nonce: nonce,
      customer_id: customer.id,
    ).payment_method.token
  end

  describe "self.find" do
    subject do
      described_class.find(token)
    end

    context "when payment method exists" do
      it "returns a payment method" do
        sepa_direct_debit_account = subject
        expect(sepa_direct_debit_account).to be_a(Braintree::SepaDirectDebitAccount)
        expect(sepa_direct_debit_account.last_4).to eq("1234")
        expect(sepa_direct_debit_account.default).to eq(true)
        expect(sepa_direct_debit_account.customer_id).to eq(customer.id)
        expect(sepa_direct_debit_account.global_id).not_to be_empty
        expect(sepa_direct_debit_account.customer_global_id).not_to be_empty
        expect(sepa_direct_debit_account.bank_reference_token).to eq("a-fake-bank-reference-token")
        expect(sepa_direct_debit_account.mandate_type).to eq("RECURRENT")
        expect(sepa_direct_debit_account.merchant_or_partner_customer_id).to eq("a-fake-mp-customer-id")
        expect(sepa_direct_debit_account.token).not_to be_empty
        expect(sepa_direct_debit_account.image_url).not_to be_empty
        expect(sepa_direct_debit_account.created_at).to be_a Time
        expect(sepa_direct_debit_account.updated_at).to be_a Time
      end
    end

    context "when payment method does not exist" do
      let(:token) { "ABC123" }

      it "raises an error" do
        expect {
          subject
        }.to raise_error(Braintree::NotFoundError)
      end
    end

    context "subscriptions" do
      it "returns subscriptions associated with a SEPA direct debit account" do
        customer = Braintree::Customer.create!

        subscription1 = Braintree::Subscription.create(
          :payment_method_token => token,
          :plan_id => SpecHelper::TriallessPlan[:id],
        ).subscription

        subscription2 = Braintree::Subscription.create(
          :payment_method_token => token,
          :plan_id => SpecHelper::TriallessPlan[:id],
        ).subscription

        sepa_debit_account = Braintree::SepaDirectDebitAccount.find(token)
        subscription_ids = sepa_debit_account.subscriptions.map { |h| h[:id] }.sort
        expect(subscription_ids).to eq([subscription1.id, subscription2.id].sort)
      end
    end
  end

  describe "self.delete" do
    subject do
      described_class.delete(token)
    end

    context "when payment method exists" do
      it "deletes a payment method" do
        is_expected.to be_success

        expect {
          described_class.find(token)
        }.to raise_error(Braintree::NotFoundError)
      end
    end

    context "when payment method does not exist" do
      let(:token) { "ABC123" }

      it "raises an error" do
        expect {
          subject
        }.to raise_error(Braintree::NotFoundError)
      end
    end
  end

  describe "self.sale" do
    let(:params) do
      {
        amount: 1.23,
      }
    end

    subject do
      described_class.sale(token, params)
    end

    context "when payment method exists" do
      it "creates a transaction" do
        is_expected.to be_success

        transaction = subject.transaction
        expect(transaction.amount).to eq(1.23)
        expect(transaction.status).to eq("settling")
        sepa_direct_debit_account_details = transaction.sepa_direct_debit_account_details
        expect(sepa_direct_debit_account_details).to be_a(Braintree::Transaction::SepaDirectDebitAccountDetails)
        expect(sepa_direct_debit_account_details.bank_reference_token).to eq("a-fake-bank-reference-token")
        expect(sepa_direct_debit_account_details.capture_id).not_to be_empty
        expect(sepa_direct_debit_account_details.debug_id).to be_nil
        expect(sepa_direct_debit_account_details.global_id).not_to be_empty
        expect(sepa_direct_debit_account_details.last_4).to eq("1234")
        expect(sepa_direct_debit_account_details.mandate_type).to eq("RECURRENT")
        expect(sepa_direct_debit_account_details.merchant_or_partner_customer_id).to eq("a-fake-mp-customer-id")
        expect(sepa_direct_debit_account_details.paypal_v2_order_id).to be_nil
        expect(sepa_direct_debit_account_details.refund_from_transaction_fee_amount).to be_nil
        expect(sepa_direct_debit_account_details.refund_from_transaction_fee_currency_iso_code).to be_nil
        expect(sepa_direct_debit_account_details.refund_id).to be_nil
        expect(sepa_direct_debit_account_details.settlement_type).to be_nil
        expect(sepa_direct_debit_account_details.token).to eq(token)
        expect(sepa_direct_debit_account_details.transaction_fee_amount).to eq("0.01")
        expect(sepa_direct_debit_account_details.transaction_fee_currency_iso_code).to eq("USD")
      end
    end

    context "when payment method does not exist" do
      let(:token) { "ABC123" }

      it "not raises an error" do
        expect {
          subject
        }.to_not raise_error
      end
    end
  end

  describe "self.sale!" do
    let(:params) do
      {
        amount: 1.23,
      }
    end

    subject do
      described_class.sale!(token, params)
    end

    context "when payment method exists" do
      it "creates a transaction" do
        transaction = subject
        expect(transaction.amount).to eq(1.23)
        expect(transaction.status).to eq("settling")
        sepa_direct_debit_account_details = transaction.sepa_direct_debit_account_details
        expect(sepa_direct_debit_account_details).to be_a(Braintree::Transaction::SepaDirectDebitAccountDetails)
        expect(sepa_direct_debit_account_details.bank_reference_token).to eq("a-fake-bank-reference-token")
        expect(sepa_direct_debit_account_details.capture_id).not_to be_empty
        expect(sepa_direct_debit_account_details.debug_id).to be_nil
        expect(sepa_direct_debit_account_details.global_id).not_to be_empty
        expect(sepa_direct_debit_account_details.last_4).to eq("1234")
        expect(sepa_direct_debit_account_details.mandate_type).to eq("RECURRENT")
        expect(sepa_direct_debit_account_details.merchant_or_partner_customer_id).to eq("a-fake-mp-customer-id")
        expect(sepa_direct_debit_account_details.paypal_v2_order_id).to be_nil
        expect(sepa_direct_debit_account_details.refund_from_transaction_fee_amount).to be_nil
        expect(sepa_direct_debit_account_details.refund_from_transaction_fee_currency_iso_code).to be_nil
        expect(sepa_direct_debit_account_details.refund_id).to be_nil
        expect(sepa_direct_debit_account_details.settlement_type).to be_nil
        expect(sepa_direct_debit_account_details.token).to eq(token)
        expect(sepa_direct_debit_account_details.transaction_fee_amount).to eq("0.01")
        expect(sepa_direct_debit_account_details.transaction_fee_currency_iso_code).to eq("USD")
      end
    end

    context "when payment method does not exist" do
      let(:token) { "ABC123" }

      it "not raises an error" do
        expect {
          subject
        }.to raise_error(Braintree::ValidationsFailed)
      end
    end
  end
end
