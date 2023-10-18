require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::Transaction do
  describe "self.create us bank account" do
    context "compliant merchant" do
      before do
        Braintree::Configuration.merchant_id = "integration2_merchant_id"
        Braintree::Configuration.public_key = "integration2_public_key"
        Braintree::Configuration.private_key = "integration2_private_key"
      end

      context "not plaid-verified" do
        let(:non_plaid_nonce) { generate_non_plaid_us_bank_account_nonce }
        let(:invalid_nonce) { generate_invalid_us_bank_account_nonce }

        context "nonce" do
          it "sale fails for valid nonce" do
            result = Braintree::Transaction.create(
              :type => "sale",
              :amount => Braintree::Test::TransactionAmounts::Authorize,
              :merchant_account_id => SpecHelper::AnotherUsBankMerchantAccountId,
              :payment_method_nonce => non_plaid_nonce,
              :options => {
                :submit_for_settlement => true,
              },
            )
            expect(result.success?).to eq(false)
            expect(result.errors.for(:transaction).on(:payment_method_nonce)[0].code).to eq(Braintree::ErrorCodes::Transaction::UsBankAccountNonceMustBePlaidVerified)
          end

          it "sale fails for invalid nonce" do
            result = Braintree::Transaction.create(
              :type => "sale",
              :amount => Braintree::Test::TransactionAmounts::Authorize,
              :merchant_account_id => SpecHelper::AnotherUsBankMerchantAccountId,
              :payment_method_nonce => invalid_nonce,
              :options => {
                :submit_for_settlement => true,
              },
            )
            expect(result.success?).to eq(false)
            expect(result.errors.for(:transaction).on(:payment_method_nonce)[0].code).to eq(Braintree::ErrorCodes::Transaction::PaymentMethodNonceUnknown)
          end
        end

        context "token" do
          it "sale succeeds for verified token" do
            result = Braintree::PaymentMethod.create(
              :payment_method_nonce => non_plaid_nonce,
              :customer_id => Braintree::Customer.create.customer.id,
              :options => {
                :us_bank_account_verification_method => "independent_check",
                :verification_merchant_account_id => SpecHelper::AnotherUsBankMerchantAccountId,
              },
            )
            payment_method = result.payment_method

            expect(payment_method.verifications.count).to eq(1)
            payment_method.verifications.first.status == Braintree::UsBankAccountVerification::Status::Verified
            payment_method.verifications.first.verification_method == Braintree::UsBankAccountVerification::VerificationMethod::IndependentCheck
            expect(payment_method.verifications.first.id).not_to be_empty
            expect(payment_method.verifications.first.verification_determined_at).to be_a Time
            expect(payment_method.verified).to eq(true)

            result = Braintree::Transaction.create(
              :type => "sale",
              :amount => Braintree::Test::TransactionAmounts::Authorize,
              :merchant_account_id => SpecHelper::AnotherUsBankMerchantAccountId,
              :payment_method_token => payment_method.token,
              :options => {
                :submit_for_settlement => true,
              },
            )

            expect(result.success?).to eq(true)
          end

          it "sale fails for unverified token" do
            payment_method = Braintree::PaymentMethod.create(
              :payment_method_nonce => non_plaid_nonce,
              :customer_id => Braintree::Customer.create.customer.id,
              :options => {
                :verification_merchant_account_id => SpecHelper::AnotherUsBankMerchantAccountId,
              },
            ).payment_method

            expect(payment_method.verifications.count).to eq(0)
            expect(payment_method.verified).to eq(false)

            result = Braintree::Transaction.create(
              :type => "sale",
              :amount => Braintree::Test::TransactionAmounts::Authorize,
              :merchant_account_id => SpecHelper::AnotherUsBankMerchantAccountId,
              :payment_method_token => payment_method.token,
              :options => {
                :submit_for_settlement => true,
              },
            )

            expect(result.success?).to eq(false)
            expect(result.errors.for(:transaction)[0].code).to eq(Braintree::ErrorCodes::Transaction::UsBankAccountNotVerified)
          end
        end
      end
    end

    context "exempt merchant" do
      before do
        Braintree::Configuration.merchant_id = "integration_merchant_id"
        Braintree::Configuration.public_key = "integration_public_key"
        Braintree::Configuration.private_key = "integration_private_key"
      end

      context "not plaid-verified" do
        let(:non_plaid_nonce) { generate_non_plaid_us_bank_account_nonce }
        let(:invalid_nonce) { generate_invalid_us_bank_account_nonce }

        context "nonce" do
          it "sale succeeds for valid nonce" do
            result = Braintree::Transaction.create(
              :type => "sale",
              :amount => Braintree::Test::TransactionAmounts::Authorize,
              :merchant_account_id => SpecHelper::UsBankMerchantAccountId,
              :payment_method_nonce => non_plaid_nonce,
              :options => {
                :submit_for_settlement => true,
              },
            )
            expect(result.success?).to eq(true)

            transaction = result.transaction

            expect(transaction.id).to match(/^\w{6,}$/)
            expect(transaction.type).to eq("sale")
            expect(transaction.amount).to eq(BigDecimal(Braintree::Test::TransactionAmounts::Authorize))
            expect(transaction.status).to eq(Braintree::Transaction::Status::SettlementPending)
            expect(transaction.us_bank_account_details.routing_number).to eq("021000021")
            expect(transaction.us_bank_account_details.last_4).to eq("0000")
            expect(transaction.us_bank_account_details.account_type).to eq("checking")
            expect(transaction.us_bank_account_details.account_holder_name).to eq("John Doe")
            expect(transaction.us_bank_account_details.bank_name).to match(/CHASE/)
            expect(transaction.us_bank_account_details.ach_mandate.text).to eq("cl mandate text")
            expect(transaction.us_bank_account_details.ach_mandate.accepted_at).to be_a Time
          end

          it "sale fails for invalid nonce" do
            result = Braintree::Transaction.create(
              :type => "sale",
              :amount => Braintree::Test::TransactionAmounts::Authorize,
              :merchant_account_id => SpecHelper::UsBankMerchantAccountId,
              :payment_method_nonce => invalid_nonce,
              :options => {
                :submit_for_settlement => true,
              },
            )
            expect(result.success?).to eq(false)
            expect(result.errors.for(:transaction).on(:payment_method_nonce)[0].code).to eq(Braintree::ErrorCodes::Transaction::PaymentMethodNonceUnknown)
          end
        end

        context "token" do
          it "sale succeeds for unverified token" do
            result = Braintree::PaymentMethod.create(
              :payment_method_nonce => non_plaid_nonce,
              :customer_id => Braintree::Customer.create.customer.id,
              :options => {
                :verification_merchant_account_id => SpecHelper::UsBankMerchantAccountId,
              },
            )
            payment_method = result.payment_method

            expect(payment_method.verifications.count).to eq(1)
            payment_method.verifications.first.status == Braintree::UsBankAccountVerification::Status::Verified
            payment_method.verifications.first.verification_method == Braintree::UsBankAccountVerification::VerificationMethod::IndependentCheck
            expect(payment_method.verifications.first.id).not_to be_empty
            expect(payment_method.verifications.first.verification_determined_at).to be_a Time
            expect(payment_method.verified).to eq(true)

            result = Braintree::Transaction.create(
              :type => "sale",
              :amount => Braintree::Test::TransactionAmounts::Authorize,
              :merchant_account_id => SpecHelper::UsBankMerchantAccountId,
              :payment_method_token => payment_method.token,
              :options => {
                :submit_for_settlement => true,
              },
            )

            expect(result.success?).to eq(true)
          end
        end
      end
    end
  end
end
