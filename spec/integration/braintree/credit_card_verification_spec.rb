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
      found_verification.credit_card.should == created_verification.credit_card
    end

    it "raises a NotFoundError exception if verification cannot be found" do
      expect do
        Braintree::CreditCardVerification.find("invalid-id")
      end.to raise_error(Braintree::NotFoundError, 'verification with id "invalid-id" not found')
    end

    describe "card type indicators" do
      it "returns prepaid on a prepaid card" do
        cardholder_name = "Tom #{rand(1_000_000)} Smith"

        result = Braintree::Customer.create(
          :credit_card => {
          :cardholder_name => cardholder_name,
          :expiration_date => "05/2012",
          :number => Braintree::Test::CreditCardNumbers::CardTypeIndicators::Prepaid,
          :cvv => '200',
          :options => {
            :verify_card => true
        }
        })

        search_results = Braintree::CreditCardVerification.search do |search|
          search.credit_card_cardholder_name.is cardholder_name
        end

        verification_id = search_results.first.id

        found_verification = Braintree::CreditCardVerification.find(verification_id)
        found_verification.credit_card[:prepaid].should == Braintree::CreditCard::Prepaid::Yes
      end
    end
  end
end
