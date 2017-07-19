# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::Dispute do
  let(:transaction) do
    result = Braintree::Transaction.sale(
      :amount => '10.00',
      :credit_card => {
        :expiration_date => '01/2020',
        :number => Braintree::Test::CreditCardNumbers::Disputes::Chargeback
      },
      :options => {
        :submit_for_settlement => true
      }
    )

    result.transaction
  end

  let(:dispute) { transaction.disputes.first }

  describe "self.accept" do
    it "changes the dispute status to accepted" do
      result = Braintree::Dispute.accept(dispute.id)

      result.success?.should == true

      refreshed_dispute = Braintree::Dispute.find(dispute.id)
      refreshed_dispute.status.should == Braintree::Dispute::Status::Accepted
    end

    it "returns an error response if the dispute is not in open status" do
      result = Braintree::Dispute.accept("wells_dispute")
      result.success?.should == false
      result.errors.for(:dispute)[0].code.should == Braintree::ErrorCodes::Dispute::CanOnlyAcceptOpenDispute
      result.errors.for(:dispute)[0].message.should == "Disputes can only be accepted when they are in an Open state"
    end

    it "raises a NotFound exception if the dispute cannot be found" do
      expect do
        Braintree::Dispute.accept("invalid-id")
      end.to raise_error(Braintree::NotFoundError, 'dispute with id invalid-id not found')
    end
  end

  describe "self.find" do
    it "finds the dispute with the given id" do
      dispute = Braintree::Dispute.find("open_dispute")

      dispute.amount_disputed.should == 31.0
      dispute.amount_won.should == 0.0
      dispute.id.should == "open_dispute"
      dispute.status.should == Braintree::Dispute::Status::Open
      dispute.transaction.amount.should == 31.0
      dispute.transaction.id.should == "open_disputed_transaction"
    end

    it "raises an ArgumentError if dispute_id is not a string" do
      expect do
        Braintree::Dispute.find(Object.new)
      end.to raise_error(ArgumentError, "dispute_id contains invalid characters")
    end

    it "raises an ArgumentError if dispute_id is blank" do
      expect do
        Braintree::Dispute.find("")
      end.to raise_error(ArgumentError, "dispute_id contains invalid characters")
    end

    it "raises a NotFoundError exception if the dispute cannot be found" do
      expect do
        Braintree::Dispute.find("invalid-id")
      end.to raise_error(Braintree::NotFoundError, 'dispute with id "invalid-id" not found')
    end
  end
end
