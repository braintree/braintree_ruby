
require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Braintree
  describe ClientToken do
    describe "self.generate" do
      it "delegates to ClientTokenGateway#generate" do
        options = {:foo => :bar}
        client_token_gateway = double(:client_token_gateway)
        expect(client_token_gateway).to receive(:generate).with(options).once
        allow(ClientTokenGateway).to receive(:new).and_return(client_token_gateway)
        ClientToken.generate(options)
      end

      it "can't overwrite public_key, or created_at" do
        expect {
          Braintree::ClientToken.generate(
            :public_key => "bad_key",
            :created_at => "bad_time",
          )
        }.to raise_error(ArgumentError, /created_at, public_key/)
      end
    end

    context "adding credit_card options with no customer ID" do
      %w(verify_card fail_on_duplicate_payment_method make_default fail_on_duplicate_payment_method_for_customer).each do |option_name|
        it "raises an ArgumentError if #{option_name} is present" do
          expect do
            Braintree::ClientToken.generate(
              option_name.to_sym => true,
            )
          end.to raise_error(ArgumentError, /#{option_name}/)
        end
      end
    end
  end
end
