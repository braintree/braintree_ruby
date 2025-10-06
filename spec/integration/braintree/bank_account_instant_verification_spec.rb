require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::BankAccountInstantVerificationGateway do
  before do
    @gateway = Braintree::Gateway.new(
      :environment => :development,
      :merchant_id => "integration2_merchant_id",
      :public_key => "integration2_public_key",
      :private_key => "integration2_private_key",
    )

    @us_bank_gateway = Braintree::Gateway.new(
      :environment => :development,
      :merchant_id => "integration_merchant_id",
      :public_key => "integration_public_key",
      :private_key => "integration_private_key",
    )
  end

  describe "create_jwt" do
    it "creates a jwt with valid request" do
      request = Braintree::BankAccountInstantVerificationJwtRequest.new(
        :business_name => "15Ladders",
        :return_url => "https://example.com/success",
        :cancel_url => "https://example.com/cancel",
      )

      result = @gateway.bank_account_instant_verification.create_jwt(request)

      unless result.success?
        puts "DEBUG: Result failed!"
        puts "DEBUG: Errors: #{result.errors.inspect}" if result.respond_to?(:errors)
      end

      expect(result.success?).to eq(true)
      expect(result.bank_account_instant_verification_jwt).to have_attributes(
        jwt: a_string_matching(/.+/),
      )
    end

    it "fails with invalid business name" do
      request = Braintree::BankAccountInstantVerificationJwtRequest.new(
        :business_name => "", # Empty business name should cause validation error
        :return_url => "https://example.com/return",
        :cancel_url => "https://example.com/cancel",
      )

      result = @gateway.bank_account_instant_verification.create_jwt(request)

      expect(result.success?).to eq(false)
      expect(result.errors).not_to be_nil
    end

    it "fails with invalid URLs" do
      request = Braintree::BankAccountInstantVerificationJwtRequest.new(
        :business_name => "15Ladders",
        :return_url => "not-a-valid-url",
        :cancel_url => "also-not-valid",
      )

      result = @us_bank_gateway.bank_account_instant_verification.create_jwt(request)

      expect(result.success?).to eq(false)
      expect(result.errors).not_to be_nil
    end
  end

  describe "charge US bank with ACH mandate" do
    it "creates transaction directly with nonce and provides ACH mandate at transaction time (instant verification)" do
      nonce = generate_us_bank_account_nonce_via_open_banking

      mandate_accepted_at = Time.now - 300 # 5 minutes ago

      # Create transaction directly with nonce and provide ACH mandate at transaction time (instant verification)
      transaction_request = {
        :amount => "12.34",
        :payment_method_nonce => nonce,
        :merchant_account_id => SpecHelper::UsBankMerchantAccountId, # could it be?
        :us_bank_account => {
          :ach_mandate_text => "I authorize this transaction and future debits",
          :ach_mandate_accepted_at => mandate_accepted_at
        },
        :options => {
          :submit_for_settlement => true
        }
      }

      transaction_result = @us_bank_gateway.transaction.sale(transaction_request)

      expect(transaction_result.success?).to eq(true), "Expected transaction success but got failure with validation errors (see console output)"
      transaction = transaction_result.transaction

      expected_transaction = {
        id: a_string_matching(/.+/),
        amount: BigDecimal("12.34"),
        us_bank_account_details: have_attributes(
          ach_mandate: have_attributes(
            text: "I authorize this transaction and future debits",
            accepted_at: be_a(Time),
          ),
          account_holder_name: "Dan Schulman",
          last_4: "1234",
          routing_number: "021000021",
          account_type: "checking",
        )
      }

      expect(transaction).to have_attributes(expected_transaction)
    end
  end

  describe "Open Finance flow with INSTANT_VERIFICATION_ACCOUNT_VALIDATION" do
    it "tokenizes bank account via Open Finance API, vaults with and charges" do

      nonce = generate_us_bank_account_nonce_via_open_banking

      customer_result = @us_bank_gateway.customer.create({})
      expect(customer_result.success?).to eq(true)
      customer = customer_result.customer

      mandate_accepted_at = Time.now - 300

      payment_method_request = {
        :customer_id => customer.id,
        :payment_method_nonce => nonce,
        :us_bank_account => {
          :ach_mandate_text => "I authorize this transaction and future debits",
          :ach_mandate_accepted_at => mandate_accepted_at
        },
        :options => {
          :verification_merchant_account_id => SpecHelper::UsBankMerchantAccountId,
          :us_bank_account_verification_method => Braintree::UsBankAccountVerification::VerificationMethod::InstantVerificationAccountValidation
        }
      }

      payment_method_result = @us_bank_gateway.payment_method.create(payment_method_request)
      expect(payment_method_result.success?).to eq(true), "Expected payment method creation success but got failure with validation errors"

      us_bank_account = payment_method_result.payment_method

      expected_us_bank_account = {
        verifications: a_collection_containing_exactly(
          have_attributes(
            verification_method: Braintree::UsBankAccountVerification::VerificationMethod::InstantVerificationAccountValidation,
            status: "verified",
          ),
        ),
        ach_mandate: have_attributes(
          text: "I authorize this transaction and future debits",
          accepted_at: be_a(Time),
        )
      }

      expect(us_bank_account).to have_attributes(expected_us_bank_account)

      verification = us_bank_account.verifications.first
      expect(verification.verification_method).to eq(Braintree::UsBankAccountVerification::VerificationMethod::InstantVerificationAccountValidation)

      transaction_request = {
        :amount => "12.34",
        :payment_method_token => us_bank_account.token,
        :merchant_account_id => SpecHelper::UsBankMerchantAccountId,
        :options => {
          :submit_for_settlement => true
        }
      }

      transaction_result = @us_bank_gateway.transaction.sale(transaction_request)
      expect(transaction_result.success?).to eq(true), "Expected transaction success but got failure"
      transaction = transaction_result.transaction

      expected_transaction = {
        id: a_string_matching(/.+/),
        amount: BigDecimal("12.34"),
        us_bank_account_details: have_attributes(
          token: us_bank_account.token,
          ach_mandate: have_attributes(
            text: "I authorize this transaction and future debits",
            accepted_at: be_a(Time),
          ),
          last_4: "1234",
          routing_number: "021000021",
          account_type: "checking",
        )
      }

      expect(transaction).to have_attributes(expected_transaction)
    end
  end
end