require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::UsBankAccountVerification, "search" do
  let(:nonce) { generate_non_plaid_us_bank_account_nonce }
  let(:customer) do
    params = {
      :first_name => "Tom",
      :last_name => "Smith",
      :email => "tom.smith@example.com",
    }

    Braintree::Customer.create(params).customer
  end

  describe "self.find" do
    it "finds the verification with the given id" do
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :options => {
          :verification_merchant_account_id => SpecHelper::UsBankMerchantAccountId,
          :us_bank_account_verification_method => Braintree::UsBankAccountVerification::VerificationMethod::NetworkCheck,
        }
      )

      result.should be_success

      created_verification = result.payment_method.verifications.first
      found_verification = Braintree::UsBankAccountVerification.find(created_verification.id)

      found_verification.should == created_verification
    end

    it "raises a NotFoundError exception if verification cannot be found" do
      expect do
        Braintree::UsBankAccountVerification.find("invalid-id")
      end.to raise_error(Braintree::NotFoundError, 'verification with id "invalid-id" not found')
    end
  end

  describe "self.search" do
    let(:payment_method) do
      Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :options => {
          :verification_merchant_account_id => SpecHelper::UsBankMerchantAccountId,
          :us_bank_account_verification_method => Braintree::UsBankAccountVerification::VerificationMethod::NetworkCheck,
        }
      ).payment_method
    end

    let(:created_verification) do
      payment_method.verifications.first
    end

    it "searches and finds verification using verification fields" do
      found_verifications = Braintree::UsBankAccountVerification.search do |search|
        search.created_at >= (Time.now() - 120)
        search.ids.in created_verification.id
        search.status.in created_verification.status
        search.verification_method.in created_verification.verification_method
      end

      found_verifications.should include(created_verification)
    end

    it "searches and finds verifications using customer fields" do
      found_verifications = Braintree::UsBankAccountVerification.search do |search|
        search.customer_email.is customer.email
        search.customer_id.is customer.id
        search.payment_method_token.is payment_method.token
      end

      found_verifications.count.should eq(1)
    end
  end
end
