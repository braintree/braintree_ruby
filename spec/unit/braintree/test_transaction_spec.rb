require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::TestTransaction do
  describe "path traversal" do
    [
      :settle,
      :settlement_confirm,
      :settlement_decline,
      :settlement_pending,
    ].each do |method_name|
      it "self.#{method_name} raises an exception if the transaction_id is a traversal segment" do
        expect do
          Braintree::TestTransaction.public_send(method_name, "../transactions/victim_id/void")
        end.to raise_error(ArgumentError, "transaction_id contains invalid characters")
      end
    end
  end
end
