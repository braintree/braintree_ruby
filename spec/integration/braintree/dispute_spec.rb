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

  describe "self.add_text_evidence" do
    it "creates text evidence for the dispute" do
      result = Braintree::Dispute.add_text_evidence("open_dispute", "text evidence")

      result.success?.should == true
      result.evidence.comment.should == "text evidence"
      result.evidence.created_at.between?(Time.now - 10, Time.now).should == true
      result.evidence.id.should =~ /^\w{16,}$/
      result.evidence.sent_to_processor_at.should == nil
      result.evidence.url.should == nil
    end

    it "returns a NotFoundError if the dispute doesn't exist" do
      expect do
        Braintree::Dispute.add_text_evidence("unknown_dispute_id", "text evidence")
      end.to raise_error(Braintree::NotFoundError)
    end

    it "returns an error response if the dispute is not in open status" do
      result = Braintree::Dispute.add_text_evidence("wells_dispute", "text evidence")
      result.success?.should == false
      result.errors.for(:dispute)[0].code.should == Braintree::ErrorCodes::Dispute::CanOnlyAddEvidenceToOpenDispute
      result.errors.for(:dispute)[0].message.should == "Evidence can only be attached to disputes that are in an Open state"
    end

    it "returns the new evidence record in subsequent dispute finds" do
      result = Braintree::Dispute.add_text_evidence("open_dispute", "text evidence")
      dispute = Braintree::Dispute.find("open_dispute")

      expected_evidence = dispute.evidence.find { |e| e.id == result.evidence.id }
      expected_evidence.should_not == nil
      expected_evidence.comment.should == "text evidence"
    end
  end

  describe "self.finalize" do
    it "changes the dispute status to disputed" do
      result = Braintree::Dispute.finalize(dispute.id)

      result.success?.should == true

      refreshed_dispute = Braintree::Dispute.find(dispute.id)
      refreshed_dispute.status.should == Braintree::Dispute::Status::Disputed
    end

    it "returns an error response if the dispute is not in open status" do
      result = Braintree::Dispute.finalize("wells_dispute")

      result.success?.should == false
      result.errors.for(:dispute)[0].code.should == Braintree::ErrorCodes::Dispute::CanOnlyFinalizeOpenDispute
      result.errors.for(:dispute)[0].message.should == "Disputes can only be finalized when they are in an Open state"
    end

    it "raises a NotFound exception if the dispute cannot be found" do
      expect do
        Braintree::Dispute.finalize("invalid-id")
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
