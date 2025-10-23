require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::UsBankAccount do
  describe "self.find" do
    it "returns a UsBankAccount" do
      customer = Braintree::Customer.create!
      nonce = generate_non_plaid_us_bank_account_nonce

      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :options => {
          :verification_merchant_account_id => SpecHelper::UsBankMerchantAccountId,
        },
      )
      expect(result).to be_success

      us_bank_account = Braintree::UsBankAccount.find(result.payment_method.token)
      expect(us_bank_account).to be_a(Braintree::UsBankAccount)
      expect(us_bank_account.routing_number).to eq("021000021")
      expect(us_bank_account.last_4).to eq("0000")
      expect(us_bank_account.account_type).to eq("checking")
      expect(us_bank_account.account_holder_name).to eq("John Doe")
      expect(us_bank_account.bank_name).to match(/CHASE/)
      expect(us_bank_account.ach_mandate.accepted_at).to be_a Time
    end

    it "raises if the payment method token is not found" do
      expect do
        Braintree::UsBankAccount.find(generate_invalid_us_bank_account_nonce)
      end.to raise_error(Braintree::NotFoundError)
    end
  end

  context "self.sale" do
    it "creates a transaction using a us bank account and returns a result object" do
      customer = Braintree::Customer.create!
      nonce = generate_non_plaid_us_bank_account_nonce

      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :options => {
          :verification_merchant_account_id => SpecHelper::UsBankMerchantAccountId,
        },
      )
      expect(result).to be_success

      result = Braintree::UsBankAccount.sale(
        result.payment_method.token,
        :merchant_account_id => SpecHelper::UsBankMerchantAccountId,
        :amount => "100.00",
      )

      expect(result.success?).to eq(true)
      expect(result.transaction.amount).to eq(BigDecimal("100.00"))
      expect(result.transaction.type).to eq("sale")
      us_bank_account = result.transaction.us_bank_account_details
      expect(us_bank_account.routing_number).to eq("021000021")
      expect(us_bank_account.last_4).to eq("0000")
      expect(us_bank_account.account_type).to eq("checking")
      expect(us_bank_account.account_holder_name).to eq("John Doe")
      expect(us_bank_account.bank_name).to match(/CHASE/)
      expect(us_bank_account.ach_mandate.accepted_at).to be_a Time
    end
  end

  context "self.sale!" do
    it "creates a transaction using a us bank account and returns a result object" do
      customer = Braintree::Customer.create!
      nonce = generate_non_plaid_us_bank_account_nonce

      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :options => {
          :verification_merchant_account_id => SpecHelper::UsBankMerchantAccountId,
        },
      )
      expect(result).to be_success

      transaction = Braintree::UsBankAccount.sale!(
        result.payment_method.token,
        :merchant_account_id => SpecHelper::UsBankMerchantAccountId,
        :amount => "100.00",
      )

      expect(transaction.amount).to eq(BigDecimal("100.00"))
      expect(transaction.type).to eq("sale")
      us_bank_account = transaction.us_bank_account_details
      expect(us_bank_account.routing_number).to eq("021000021")
      expect(us_bank_account.last_4).to eq("0000")
      expect(us_bank_account.account_type).to eq("checking")
      expect(us_bank_account.account_holder_name).to eq("John Doe")
      expect(us_bank_account.bank_name).to match(/CHASE/)
      expect(us_bank_account.ach_mandate.accepted_at).to be_a Time
    end

    it "does not creates a transaction using a us bank account and returns raises an exception" do
      expect do
        Braintree::UsBankAccount.sale!(
          generate_invalid_us_bank_account_nonce,
          :merchant_account_id => SpecHelper::UsBankMerchantAccountId,
          :amount => "100.00",
        )
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end
end
