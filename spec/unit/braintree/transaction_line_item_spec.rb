require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::TransactionLineItem do
  describe "path traversal" do
    it "self.find_all raises an exception if the transaction_id is a traversal segment" do
      expect do
        Braintree::TransactionLineItem.find_all("../transactions/victim_id/void")
      end.to raise_error(ArgumentError, "transaction_id contains invalid characters")
    end
  end
end
