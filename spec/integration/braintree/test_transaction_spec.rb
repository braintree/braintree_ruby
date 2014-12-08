require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::TestTransaction do
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
      sale_result.transaction.status.should == Braintree::Transaction::Status::Settling

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
      sale_result.transaction.status.should == Braintree::Transaction::Status::Settling

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
      sale_result.transaction.status.should == Braintree::Transaction::Status::Settling

      settle_result = Braintree::TestTransaction.settlement_decline(sale_result.transaction.id)
      settle_result.transaction.status.should == Braintree::Transaction::Status::SettlementDeclined
      settle_result.success?.should == true
    end

    it "changes transaction status to settlement_pending" do
      sale_result = Braintree::Transaction.sale(
        :amount => "100",
        :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
        :options => {
          :submit_for_settlement => true
        }
      )
      sale_result.success?.should == true
      sale_result.transaction.status.should == Braintree::Transaction::Status::Settling

      settle_result = Braintree::TestTransaction.settlement_pending(sale_result.transaction.id)
      settle_result.transaction.status.should == Braintree::Transaction::Status::SettlementPending
      settle_result.success?.should == true
    end

    it "returns a validation error when invalid transition is specified" do
      sale_result = Braintree::Transaction.sale(
        :amount => "100",
        :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment
      )
      sale_result.success?.should == true

      settle_result = Braintree::TestTransaction.settlement_decline(sale_result.transaction.id)
      settle_result.success?.should be(false)
      settle_result.errors.for(:transaction).on(:base).first.code.should == Braintree::ErrorCodes::Transaction::CannotSimulateTransactionSettlement
    end
  end

  context "mistakenly testing in production" do
    def in_prod
      old_environment = Braintree::Configuration.environment
      Braintree::Configuration.environment = :production
      begin
        yield
      ensure
        Braintree::Configuration.environment = old_environment
      end
    end


    it "raises an exception if settle is called in a production environment" do
      expect do
        in_prod do
          Braintree::TestTransaction.settle(nil)
        end
      end.to raise_error(Braintree::TestOperationPerformedInProduction)
    end

    it "raises an exception if settlement_decline is called in a production environment" do
      expect do
        in_prod do
          Braintree::TestTransaction.settlement_decline(nil)
        end
      end.to raise_error(Braintree::TestOperationPerformedInProduction)
    end

    it "raises an exception if settlement_confirm is called in a production environment" do
      expect do
        in_prod do
          Braintree::TestTransaction.settlement_confirm(nil)
        end
      end.to raise_error(Braintree::TestOperationPerformedInProduction)
    end
  end

end
