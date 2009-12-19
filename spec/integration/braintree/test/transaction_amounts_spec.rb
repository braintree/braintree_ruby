require File.dirname(__FILE__) + "/../../spec_helper"

describe Braintree::Test::TransactionAmounts do
  describe "Authorize" do
    it "creates a transaction with status authorized" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "12/2012"
        }
      )
      transaction.status.should == "authorized"
    end
  end

  describe "Decline" do
    it "creates a transaction with status processor_declined" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "12/2012"
        }
      )
      transaction.status.should == "processor_declined"
    end
  end
end
