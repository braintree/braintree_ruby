
require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Braintree
  describe ClientToken do
    describe "self.generate" do
      it "delegates to ClientTokenGateway#generate" do
        options = {:foo => :bar}
        client_token_gateway = double(:client_token_gateway)
        client_token_gateway.should_receive(:generate).with(options).once
        ClientTokenGateway.stub(:new).and_return(client_token_gateway)
        ClientToken.generate(options)
      end
    end
  end
end
