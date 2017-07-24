# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::Dispute do
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
