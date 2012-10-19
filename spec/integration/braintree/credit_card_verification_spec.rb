require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::CreditCardVerification, "search" do
  describe "self.find" do
    it "finds the verification with the given id" do
      result = Braintree::Customer.create(
        :credit_card => {
        :cardholder_name => "Tom Smith",
        :expiration_date => "05/2012",
        :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::Visa,
        :options => {
        :verify_card => true
      }
      })

      created_verification = result.credit_card_verification

      found_verification = Braintree::CreditCardVerification.find(created_verification.id)
      found_verification.should == created_verification
    end

    it "raises a NotFoundError exception if verification cannot be found" do
      expect do
        Braintree::CreditCardVerification.find("invalid-id")
      end.to raise_error(Braintree::NotFoundError, 'verification with id "invalid-id" not found')
    end
  end
end
