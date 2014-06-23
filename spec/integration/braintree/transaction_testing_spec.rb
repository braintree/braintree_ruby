require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::Transaction do
  context "testing" do
    it "changes transaction status to settled" do
      sale_result = Braintree::Transaction.sale(
        :amount => "100",
        :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
        :options => {
        :submit_for_settlement => true
      }
      )
      sale_result.success?.should == true
      sale_result.transaction.status.should == Braintree::Transaction::Status::SubmittedForSettlement

      settle_result = Braintree::TestTransaction.settle(sale_result.transaction.id)
      settle_result.transaction.status.should == Braintree::Transaction::Status::Settled
      settle_result.success?.should == true
    end

    it "changes transaction status to settlement_confirmed" do
      sale_result = Braintree::Transaction.sale(
        :amount => "100",
        :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
        :options => {
          :submit_for_settlement => true
        }
      )
      sale_result.success?.should == true
      sale_result.transaction.status.should == Braintree::Transaction::Status::SubmittedForSettlement

      settle_result = Braintree::TestTransaction.settlement_confirm(sale_result.transaction.id)
      settle_result.transaction.status.should == Braintree::Transaction::Status::SettlementConfirmed
      settle_result.success?.should == true
    end

    it "changes transaction status to settlement_declined" do
      sale_result = Braintree::Transaction.sale(
        :amount => "100",
        :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
        :options => {
          :submit_for_settlement => true
        }
      )
      sale_result.success?.should == true
      sale_result.transaction.status.should == Braintree::Transaction::Status::SubmittedForSettlement

      settle_result = Braintree::TestTransaction.settlement_decline(sale_result.transaction.id)
      settle_result.transaction.status.should == Braintree::Transaction::Status::SettlementDeclined
      settle_result.success?.should == true
    end

    it "returns a validation error when invalid transition is specified" do
      sale_result = Braintree::Transaction.sale(
        :amount => "100",
        :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment
      )
      sale_result.success?.should == true

      settle_result = Braintree::TestTransaction.settlement_decline(sale_result.transaction.id)
      settle_result.success?.should be_false
      settle_result.errors.for(:transaction).on(:base).first.code.should == Braintree::ErrorCodes::Transaction::CannotSimulateTransactionSettlement
    end
  end
end
