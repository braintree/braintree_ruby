require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::CredentialsParser do
  describe "parse_client_credentials" do
    it "parses client credentials" do
      parser = Braintree::CredentialsParser.new
      parser.parse_client_credentials("client_id$development$integration_client_id", "client_secret$development$integration_client_secret")

      expect(parser.client_id).to eq("client_id$development$integration_client_id")
      expect(parser.client_secret).to eq("client_secret$development$integration_client_secret")
      expect(parser.environment).to eq(:development)
    end

    it "raises error on inconsistent environment" do
      parser = Braintree::CredentialsParser.new

      expect do
        parser.parse_client_credentials("client_id$development$integration_client_id", "client_secret$qa$integration_client_secret")
      end.to raise_error(Braintree::ConfigurationError, /Mismatched credential environments/)
    end

    it "raises error on nil client_id" do
      parser = Braintree::CredentialsParser.new

      expect do
        parser.parse_client_credentials(nil, "client_secret$development$integration_client_secret")
      end.to raise_error(Braintree::ConfigurationError, /Missing client_id/)
    end

    it "raises error on missing client_secret" do
      parser = Braintree::CredentialsParser.new

      expect do
        parser.parse_client_credentials("client_id$development$integration_client_id", nil)
      end.to raise_error(Braintree::ConfigurationError, /Missing client_secret/)
    end

    it "raises error on invalid client_id" do
      parser = Braintree::CredentialsParser.new

      expect do
        parser.parse_client_credentials("client_secret$development$integration_client_secret", "client_secret$development$integration_client_secret")
      end.to raise_error(Braintree::ConfigurationError, /is not a client_id/)
    end

    it "raises error on invalid client_secret" do
      parser = Braintree::CredentialsParser.new

      expect do
        parser.parse_client_credentials("client_id$development$integration_client_id", "client_id$development$integration_client_id")
      end.to raise_error(Braintree::ConfigurationError, /is not a client_secret/)
    end
  end

  describe "parse_access_token" do
    it "parses access token" do
      parser = Braintree::CredentialsParser.new
      parser.parse_access_token("access_token$development$integration_merchant_id$fb27c79dd")

      expect(parser.merchant_id).to eq("integration_merchant_id")
      expect(parser.access_token).to eq("access_token$development$integration_merchant_id$fb27c79dd")
      expect(parser.environment).to eq(:development)
    end

    it "raises error on nil access_token" do
      parser = Braintree::CredentialsParser.new

      expect do
        parser.parse_access_token(nil)
      end.to raise_error(Braintree::ConfigurationError, /Missing access_token/)
    end

    it "raises error on invalid access_token" do
      parser = Braintree::CredentialsParser.new

      expect do
        parser.parse_access_token("client_id$development$integration_client_id")
      end.to raise_error(Braintree::ConfigurationError, /is not a valid access_token/)
    end
  end
end
