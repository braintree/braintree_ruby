
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

      context "with preferred_payment_method_token" do
        let(:config) { SpecHelper::TestMerchantConfig }
        let(:gateway) { Gateway.new(config) }
        let(:http) { double(:http) }

        before do
          allow(config).to receive(:http).and_return(http)
          allow(Configuration).to receive(:gateway).and_return(gateway)
        end

        def expect_client_token_post(options)
          expect(http).to receive(:post).with(
            "#{config.base_merchant_path}/client_token",
            :client_token => options,
          ).and_return(:client_token => {:value => "client-token"})
        end

        it "renames preferred_payment_method_token to payment_method_id" do
          expect_client_token_post(
            :payment_method_id => "a-pmt",
            :version => ClientToken::DEFAULT_VERSION,
          )

          client_token = Braintree::ClientToken.generate(
            :preferred_payment_method_token => "a-pmt",
          )

          expect(client_token).to eq("client-token")
        end

        it "renames string preferred_payment_method_token to payment_method_id" do
          expect_client_token_post(
            :payment_method_id => "a-pmt",
            :version => ClientToken::DEFAULT_VERSION,
          )

          client_token = Braintree::ClientToken.generate(
            "preferred_payment_method_token" => "a-pmt",
          )

          expect(client_token).to eq("client-token")
        end

        it "renames preferred_payment_method_token when the value is nil" do
          expect_client_token_post(
            :payment_method_id => nil,
            :version => ClientToken::DEFAULT_VERSION,
          )

          client_token = Braintree::ClientToken.generate(
            :preferred_payment_method_token => nil,
          )

          expect(client_token).to eq("client-token")
        end

        it "does not mutate the caller's options hash" do
          options = {:preferred_payment_method_token => "a-pmt"}
          expect(http).to receive(:post).twice.with(
            "#{config.base_merchant_path}/client_token",
            :client_token => {
              :payment_method_id => "a-pmt",
              :version => ClientToken::DEFAULT_VERSION,
            },
          ).and_return(:client_token => {:value => "client-token"})

          expect(Braintree::ClientToken.generate(options)).to eq("client-token")
          expect(Braintree::ClientToken.generate(options)).to eq("client-token")
          expect(options).to eq(:preferred_payment_method_token => "a-pmt")
        end
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

    describe "error response handling" do
      it "correctly parses error response with nested structure" do
        error_xml = "<api-error-response><message>Invalid request</message><errors><errors type=\"array\"></errors></errors></api-error-response>"
        result = Braintree::Xml::Parser.hash_from_xml(error_xml)

        expect(result[:api_error_response]).to be_a(Hash)
        expect(result[:api_error_response][:message]).to eq("Invalid request")
        expect(result[:api_error_response][:errors]).to be_a(Hash)
      end
    end
  end
end
