require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::PaymentMethod do
  describe "self.create" do
    context "compliant merchant" do
      before do
        Braintree::Configuration.merchant_id = "integration2_merchant_id"
        Braintree::Configuration.public_key = "integration2_public_key"
        Braintree::Configuration.private_key = "integration2_private_key"
      end

      context "non plaid verified nonce" do
        let(:nonce) { generate_non_plaid_us_bank_account_nonce }

        it "succeeds and does not verify when no method provided" do
          customer = Braintree::Customer.create.customer
          result = Braintree::PaymentMethod.create(
            :payment_method_nonce => nonce,
            :customer_id => customer.id,
            :options => {
              :verification_merchant_account_id => SpecHelper::AnotherUsBankMerchantAccountId,
            },
          )

          expect(result).to be_success
          us_bank_account = result.payment_method
          expect(us_bank_account).to be_a(Braintree::UsBankAccount)
          expect(us_bank_account.routing_number).to eq("021000021")
          expect(us_bank_account.last_4).to eq("0000")
          expect(us_bank_account.account_type).to eq("checking")
          expect(us_bank_account.account_holder_name).to eq("John Doe")
          expect(us_bank_account.bank_name).to match(/CHASE/)
          expect(us_bank_account.default).to eq(true)
          expect(us_bank_account.ach_mandate.text).to eq("cl mandate text")
          expect(us_bank_account.ach_mandate.accepted_at).to be_a Time

          expect(us_bank_account.verifications.count).to eq(0)
          expect(us_bank_account.verified).to eq(false)

          expect(Braintree::PaymentMethod.find(us_bank_account.token)).to be_a(Braintree::UsBankAccount)
        end

        [
          Braintree::UsBankAccountVerification::VerificationMethod::IndependentCheck,
          Braintree::UsBankAccountVerification::VerificationMethod::NetworkCheck,
        ].each do |method|
          it "succeeds and verifies via #{method}" do
            customer = Braintree::Customer.create.customer
            result = Braintree::PaymentMethod.create(
              :payment_method_nonce => nonce,
              :customer_id => customer.id,
              :options => {
                :us_bank_account_verification_method => method,
                :verification_merchant_account_id => SpecHelper::AnotherUsBankMerchantAccountId,
              },
            )

            expect(result).to be_success
            us_bank_account = result.payment_method
            expect(us_bank_account).to be_a(Braintree::UsBankAccount)
            expect(us_bank_account.routing_number).to eq("021000021")
            expect(us_bank_account.last_4).to eq("0000")
            expect(us_bank_account.account_type).to eq("checking")
            expect(us_bank_account.account_holder_name).to eq("John Doe")
            expect(us_bank_account.bank_name).to match(/CHASE/)
            expect(us_bank_account.default).to eq(true)
            expect(us_bank_account.ach_mandate.text).to eq("cl mandate text")
            expect(us_bank_account.ach_mandate.accepted_at).to be_a Time

            expect(us_bank_account.verifications.count).to eq(1)
            expect(us_bank_account.verifications.first.status).to eq(Braintree::UsBankAccountVerification::Status::Verified)
            expect(us_bank_account.verifications.first.verification_method).to eq(method)
            expect(us_bank_account.verifications.first.id).not_to be_empty
            expect(us_bank_account.verifications.first.verification_determined_at).to be_a Time
            expect(us_bank_account.verified).to eq(true)

            expect(Braintree::PaymentMethod.find(us_bank_account.token)).to be_a(Braintree::UsBankAccount)
          end
        end

        it "succeeds and verifies with verification_add_ons for NetworkCheck with fake nonce" do
          customer = Braintree::Customer.create.customer
          result = Braintree::PaymentMethod.create(
            :payment_method_nonce => Braintree::Test::Nonce::UsBankAccount,
            :customer_id => customer.id,
            :options => {
              :us_bank_account_verification_method => Braintree::UsBankAccountVerification::VerificationMethod::NetworkCheck,
              :verification_add_ons => Braintree::UsBankAccountVerification::VerificationAddOns::CustomerVerification,
              :verification_merchant_account_id => SpecHelper::AnotherUsBankMerchantAccountId,
            },
          )

          expect(result).to be_success
          us_bank_account = result.payment_method
          expect(us_bank_account).to be_a(Braintree::UsBankAccount)
          expect(us_bank_account.routing_number).to eq("123456789")
          expect(us_bank_account.last_4).to eq("0000")
          expect(us_bank_account.account_type).to eq("checking")
          expect(us_bank_account.account_holder_name).to eq("Dan Schulman")
          expect(us_bank_account.bank_name).to match(/Wells Fargo/)
          expect(us_bank_account.default).to eq(true)
          expect(us_bank_account.ach_mandate.text).to eq("example mandate text")
          expect(us_bank_account.ach_mandate.accepted_at).to be_a Time

          expect(us_bank_account.verifications.count).to eq(1)
          expect(us_bank_account.verifications.first.status).to eq(Braintree::UsBankAccountVerification::Status::Verified)
          expect(us_bank_account.verifications.first.verification_method).to eq(Braintree::UsBankAccountVerification::VerificationMethod::NetworkCheck)
          expect(us_bank_account.verifications.first.id).not_to be_empty
          expect(us_bank_account.verifications.first.verification_determined_at).to be_a Time
          expect(us_bank_account.verifications.first.processor_response_code).to eq("1000")
          expect(us_bank_account.verified).to eq(true)

          expect(Braintree::PaymentMethod.find(us_bank_account.token)).to be_a(Braintree::UsBankAccount)
        end

        it "returns additional processor response for failed NetworkCheck" do
          customer = Braintree::Customer.create.customer
          invalid_nonce = generate_non_plaid_us_bank_account_nonce(account_number = "1000000005")
          result = Braintree::PaymentMethod.create(
            :payment_method_nonce => invalid_nonce,
            :customer_id => customer.id,
            :options => {
              :us_bank_account_verification_method => Braintree::UsBankAccountVerification::VerificationMethod::NetworkCheck,
              :verification_merchant_account_id => SpecHelper::AnotherUsBankMerchantAccountId,
            },
          )

          expect(result).to be_success
          us_bank_account = result.payment_method
          expect(us_bank_account).to be_a(Braintree::UsBankAccount)
          expect(us_bank_account.routing_number).to eq("021000021")
          expect(us_bank_account.last_4).to eq("0005")
          expect(us_bank_account.account_type).to eq("checking")
          expect(us_bank_account.account_holder_name).to eq("John Doe")
          expect(us_bank_account.bank_name).to match(/CHASE/)
          expect(us_bank_account.default).to eq(true)
          expect(us_bank_account.ach_mandate.text).to eq("cl mandate text")
          expect(us_bank_account.ach_mandate.accepted_at).to be_a Time

          expect(us_bank_account.verifications.count).to eq(1)
          expect(us_bank_account.verifications.first.status).to eq(Braintree::UsBankAccountVerification::Status::ProcessorDeclined)
          expect(us_bank_account.verifications.first.verification_method).to eq(Braintree::UsBankAccountVerification::VerificationMethod::NetworkCheck)
          expect(us_bank_account.verifications.first.id).not_to be_empty
          expect(us_bank_account.verifications.first.verification_determined_at).to be_a Time
          expect(us_bank_account.verifications.first.processor_response_code).to eq("2061")
          expect(us_bank_account.verifications.first.additional_processor_response).to eq("Invalid routing number")

          expect(us_bank_account.verified).to eq(false)

          expect(Braintree::PaymentMethod.find(us_bank_account.token)).to be_a(Braintree::UsBankAccount)
        end
      end

      it "fails with invalid nonce" do
        customer = Braintree::Customer.create.customer
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => generate_invalid_us_bank_account_nonce,
          :customer_id => customer.id,
        )

        expect(result).not_to be_success
        expect(result.errors.for(:payment_method).on(:payment_method_nonce)[0].code).to eq(Braintree::ErrorCodes::PaymentMethod::PaymentMethodNonceUnknown)
      end
    end

    context "exempt merchant" do
      it "fails with invalid nonce" do
        customer = Braintree::Customer.create.customer
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => generate_invalid_us_bank_account_nonce,
          :customer_id => customer.id,
        )

        expect(result).not_to be_success
        expect(result.errors.for(:payment_method).on(:payment_method_nonce)[0].code).to eq(Braintree::ErrorCodes::PaymentMethod::PaymentMethodNonceUnknown)
      end
    end
  end

  context "self.update" do
    context "compliant merchant" do
      before do
        Braintree::Configuration.merchant_id = "integration2_merchant_id"
        Braintree::Configuration.public_key = "integration2_public_key"
        Braintree::Configuration.private_key = "integration2_private_key"
      end

      context "unverified token" do
        let(:payment_method) do
          customer = Braintree::Customer.create.customer
          result = Braintree::PaymentMethod.create(
            :payment_method_nonce => generate_non_plaid_us_bank_account_nonce,
            :customer_id => customer.id,
            :options => {
              :verification_merchant_account_id => SpecHelper::AnotherUsBankMerchantAccountId,
            },
          ).payment_method
        end

        [
          Braintree::UsBankAccountVerification::VerificationMethod::IndependentCheck,
          Braintree::UsBankAccountVerification::VerificationMethod::NetworkCheck,
        ].each do |method|
          it "succeeds and verifies via #{method}" do
            result = Braintree::PaymentMethod.update(
              payment_method.token,
              :options => {
                :verification_merchant_account_id => SpecHelper::AnotherUsBankMerchantAccountId,
                :us_bank_account_verification_method => method,
              },
            )

            expect(result).to be_success

            us_bank_account = result.payment_method
            expect(us_bank_account).to be_a(Braintree::UsBankAccount)
            expect(us_bank_account.routing_number).to eq("021000021")
            expect(us_bank_account.last_4).to eq("0000")
            expect(us_bank_account.account_type).to eq("checking")
            expect(us_bank_account.account_holder_name).to eq("John Doe")
            expect(us_bank_account.bank_name).to match(/CHASE/)
            expect(us_bank_account.default).to eq(true)
            expect(us_bank_account.ach_mandate.text).to eq("cl mandate text")
            expect(us_bank_account.ach_mandate.accepted_at).to be_a Time

            expect(us_bank_account.verifications.count).to eq(1)
            expect(us_bank_account.verifications.first.status).to eq(Braintree::UsBankAccountVerification::Status::Verified)
            expect(us_bank_account.verifications.first.verification_method).to eq(method)
            expect(us_bank_account.verifications.first.id).not_to be_empty
            expect(us_bank_account.verifications.first.verification_determined_at).to be_a Time
            expect(us_bank_account.verified).to eq(true)

            expect(Braintree::PaymentMethod.find(us_bank_account.token)).to be_a(Braintree::UsBankAccount)
          end
        end

        it "fails with invalid verification method" do
          result = Braintree::PaymentMethod.update(
            payment_method.token,
            :options => {
              :verification_merchant_account_id => SpecHelper::AnotherUsBankMerchantAccountId,
              :us_bank_account_verification_method => "blahblah",
            },
          )

          expect(result).not_to be_success
          expect(result.errors.for(:options).first.code).to eq(Braintree::ErrorCodes::PaymentMethod::Options::UsBankAccountVerificationMethodIsInvalid)
        end
      end
    end

    context "exempt merchant" do
      before do
        Braintree::Configuration.merchant_id = "integration_merchant_id"
        Braintree::Configuration.public_key = "integration_public_key"
        Braintree::Configuration.private_key = "integration_private_key"
      end

      context "unverified token" do
        let(:payment_method) do
          customer = Braintree::Customer.create.customer
          result = Braintree::PaymentMethod.create(
            :payment_method_nonce => generate_non_plaid_us_bank_account_nonce,
            :customer_id => customer.id,
            :options => {
              :verification_merchant_account_id => SpecHelper::UsBankMerchantAccountId,
            },
          ).payment_method
        end

        [
          Braintree::UsBankAccountVerification::VerificationMethod::IndependentCheck,
          Braintree::UsBankAccountVerification::VerificationMethod::NetworkCheck,
        ].each do |method|
          it "succeeds and verifies via #{method}" do
            result = Braintree::PaymentMethod.update(
              payment_method.token,
              :options => {
                :verification_merchant_account_id => SpecHelper::UsBankMerchantAccountId,
                :us_bank_account_verification_method => method,
              },
            )

            expect(result).to be_success

            us_bank_account = result.payment_method
            expect(us_bank_account).to be_a(Braintree::UsBankAccount)
            expect(us_bank_account.routing_number).to eq("021000021")
            expect(us_bank_account.last_4).to eq("0000")
            expect(us_bank_account.account_type).to eq("checking")
            expect(us_bank_account.account_holder_name).to eq("John Doe")
            expect(us_bank_account.bank_name).to match(/CHASE/)
            expect(us_bank_account.default).to eq(true)
            expect(us_bank_account.ach_mandate.text).to eq("cl mandate text")
            expect(us_bank_account.ach_mandate.accepted_at).to be_a Time

            expect(us_bank_account.verifications.count).to eq(2)
            verification = us_bank_account.verifications.find do |verification|
              verification.verification_method == method
            end
            expect(verification.status).to eq(Braintree::UsBankAccountVerification::Status::Verified)
            expect(verification.id).not_to be_empty
            expect(verification.verification_determined_at).to be_a Time
            expect(us_bank_account.verified).to eq(true)

            expect(Braintree::PaymentMethod.find(us_bank_account.token)).to be_a(Braintree::UsBankAccount)
          end
        end

        it "fails with invalid verification method" do
          result = Braintree::PaymentMethod.update(
            payment_method.token,
            :options => {
              :us_bank_account_verification_method => "blahblah",
            },
          )

          expect(result).not_to be_success
          expect(result.errors.for(:options).first.code).to eq(Braintree::ErrorCodes::PaymentMethod::Options::UsBankAccountVerificationMethodIsInvalid)
        end
      end
    end
  end
end
