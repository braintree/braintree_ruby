
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

    context "adding credit_card options with no customer ID" do
      %w(verify_card fail_on_duplicate_payment_method make_default).each do |option_name|
        it "raises an ArgumentError if #{option_name} is present" do
          expect do
            Braintree::ClientToken.generate(
              option_name.to_sym => true
            )
          end.to raise_error(ArgumentError, /#{option_name}/)
        end
      end
    end
  end
end
