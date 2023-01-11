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
        sepa_direct_debit_account.should be_a(Braintree::SepaDirectDebitAccount)
        sepa_direct_debit_account.last_4.should == "1234"
        sepa_direct_debit_account.default.should == true
        sepa_direct_debit_account.customer_id.should == customer.id
        sepa_direct_debit_account.global_id.should_not be_empty
        sepa_direct_debit_account.customer_global_id.should_not be_empty
        sepa_direct_debit_account.bank_reference_token.should == "a-fake-bank-reference-token"
        sepa_direct_debit_account.mandate_type.should == "RECURRENT"
        sepa_direct_debit_account.merchant_or_partner_customer_id.should == "a-fake-mp-customer-id"
        sepa_direct_debit_account.token.should_not be_empty
        sepa_direct_debit_account.image_url.should_not be_empty
        sepa_direct_debit_account.created_at.should be_a Time
        sepa_direct_debit_account.updated_at.should be_a Time
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

  describe "self.delete" do
    subject do
      described_class.delete(token)
    end

    context "when payment method exists" do
      it "deletes a payment method" do
        should be_success

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
        should be_success

        transaction = subject.transaction
        transaction.amount.should eq(1.23)
        transaction.status.should == "settling"
        sepa_direct_debit_account_details = transaction.sepa_direct_debit_account_details
        sepa_direct_debit_account_details.should be_a(Braintree::Transaction::SepaDirectDebitAccountDetails)
        sepa_direct_debit_account_details.bank_reference_token.should == "a-fake-bank-reference-token"
        sepa_direct_debit_account_details.capture_id.should_not be_empty
        sepa_direct_debit_account_details.debug_id.should be_nil
        sepa_direct_debit_account_details.global_id.should_not be_empty
        sepa_direct_debit_account_details.last_4.should == "1234"
        sepa_direct_debit_account_details.mandate_type.should == "RECURRENT"
        sepa_direct_debit_account_details.merchant_or_partner_customer_id.should == "a-fake-mp-customer-id"
        sepa_direct_debit_account_details.paypal_v2_order_id.should be_nil
        sepa_direct_debit_account_details.refund_from_transaction_fee_amount.should be_nil
        sepa_direct_debit_account_details.refund_from_transaction_fee_currency_iso_code.should be_nil
        sepa_direct_debit_account_details.refund_id.should be_nil
        sepa_direct_debit_account_details.settlement_type.should be_nil
        sepa_direct_debit_account_details.token.should == token
        sepa_direct_debit_account_details.transaction_fee_amount.should == "0.01"
        sepa_direct_debit_account_details.transaction_fee_currency_iso_code.should == "USD"
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
        transaction.amount.should eq(1.23)
        transaction.status.should == "settling"
        sepa_direct_debit_account_details = transaction.sepa_direct_debit_account_details
        sepa_direct_debit_account_details.should be_a(Braintree::Transaction::SepaDirectDebitAccountDetails)
        sepa_direct_debit_account_details.bank_reference_token.should == "a-fake-bank-reference-token"
        sepa_direct_debit_account_details.capture_id.should_not be_empty
        sepa_direct_debit_account_details.debug_id.should be_nil
        sepa_direct_debit_account_details.global_id.should_not be_empty
        sepa_direct_debit_account_details.last_4.should == "1234"
        sepa_direct_debit_account_details.mandate_type.should == "RECURRENT"
        sepa_direct_debit_account_details.merchant_or_partner_customer_id.should == "a-fake-mp-customer-id"
        sepa_direct_debit_account_details.paypal_v2_order_id.should be_nil
        sepa_direct_debit_account_details.refund_from_transaction_fee_amount.should be_nil
        sepa_direct_debit_account_details.refund_from_transaction_fee_currency_iso_code.should be_nil
        sepa_direct_debit_account_details.refund_id.should be_nil
        sepa_direct_debit_account_details.settlement_type.should be_nil
        sepa_direct_debit_account_details.token.should == token
        sepa_direct_debit_account_details.transaction_fee_amount.should == "0.01"
        sepa_direct_debit_account_details.transaction_fee_currency_iso_code.should == "USD"
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
