require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::TransactionSearch do
	it "overrides previous 'is' with new 'is' for the same field" do
		search = Braintree::TransactionSearch.new
		search.billing_company.is "one"
		search.billing_company.is "two"
		search.to_hash.should == {:billing_company => {:is => "two"}}
	end

	it "overrides previous 'in' with new 'in' for the same field" do
		search = Braintree::TransactionSearch.new
		search.status.in Braintree::Transaction::Status::Authorized
		search.status.in Braintree::Transaction::Status::SubmittedForSettlement
		search.to_hash.should == {:status => [Braintree::Transaction::Status::SubmittedForSettlement]}
	end

  it "raises if the operator 'is' is left off" do
    search = Braintree::TransactionSearch.new
    expect do
      search.billing_company "one"
    end.to raise_error(RuntimeError, "An operator is required")
  end

  context "when a transaction search receives an 422 response" do
    it "raises a timeout exception" do
      gateway_mock = stub(:config => OpenStruct.new(:http => true))
      gateway_mock.config.http.stub(:post).and_return({:unprocessable_entity=>""})

      transaction_gateway = Braintree::TransactionGateway.new(gateway_mock)

      expect {
        transaction_gateway.search
      }.to raise_error(Braintree::DownForMaintenanceError)
    end
  end
end
