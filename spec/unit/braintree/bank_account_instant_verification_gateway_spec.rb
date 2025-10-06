require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::BankAccountInstantVerificationGateway do
  let(:gateway) { double("gateway") }
  let(:config) { double("config") }
  let(:graphql_client) { double("graphql_client") }
  let(:bank_account_instant_verification_gateway) { Braintree::BankAccountInstantVerificationGateway.new(gateway) }

  before do
    allow(gateway).to receive(:config).and_return(config)
    allow(gateway).to receive(:graphql_client).and_return(graphql_client)
  end

  describe "create_jwt" do
    let(:request) do
      Braintree::BankAccountInstantVerificationJwtRequest.new(
        :business_name => "Test Business",
        :return_url => "https://example.com/success",
        :cancel_url => "https://example.com/cancel",
      )
    end

    it "returns success result with valid response" do
      mock_response = {
        :data => {
          :createBankAccountInstantVerificationJwt => {
            :jwt => "test-jwt-token"
          }
        }
      }

      allow(graphql_client).to receive(:query).and_return(mock_response)

      result = bank_account_instant_verification_gateway.create_jwt(request)

      expect(result.success?).to eq(true)
      expect(result.bank_account_instant_verification_jwt).not_to be_nil
      expect(result.bank_account_instant_verification_jwt.jwt).to eq("test-jwt-token")
    end

    it "returns error result with validation errors" do
      mock_response = {
        :errors => [
          {
            :message => "Validation error",
            :extensions => {}
          }
        ]
      }

      allow(graphql_client).to receive(:query).and_return(mock_response)

      result = bank_account_instant_verification_gateway.create_jwt(request)

      expect(result.success?).to eq(false)
      expect(result.errors).not_to be_nil
    end

    it "calls GraphQL client with correct mutation" do
      mock_response = {
        :data => {
          :createBankAccountInstantVerificationJwt => {
            :jwt => "test-jwt-token"
          }
        }
      }

      expect(graphql_client).to receive(:query).with(
        /mutation CreateBankAccountInstantVerificationJwt/,
        {:input=>{:businessName=>"Test Business", :cancelUrl=>"https://example.com/cancel", :returnUrl=>"https://example.com/success"}},
      ).and_return(mock_response)

      bank_account_instant_verification_gateway.create_jwt(request)
    end

    it "works with minimal request" do
      minimal_request = Braintree::BankAccountInstantVerificationJwtRequest.new(
        :business_name => "Test Business",
        :return_url => "https://example.com/success",
      )

      mock_response = {
        :data => {
          :createBankAccountInstantVerificationJwt => {
            :jwt => "test-jwt-token"
          }
        }
      }

      allow(graphql_client).to receive(:query).and_return(mock_response)

      result = bank_account_instant_verification_gateway.create_jwt(minimal_request)

      expect(result.success?).to eq(true)
      expect(result.bank_account_instant_verification_jwt.jwt).to eq("test-jwt-token")
    end
  end
end