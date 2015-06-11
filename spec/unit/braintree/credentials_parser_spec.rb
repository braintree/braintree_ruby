require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::CredentialsParser do
  context "client credentials" do
    it "parses client credentials" do
      parser = Braintree::CredentialsParser.new(
        :client_id => "client_id$development$integration_client_id",
        :client_secret => "client_secret$development$integration_client_secret",
      )

      parser.client_id.should == "client_id$development$integration_client_id"
      parser.client_secret.should == "client_secret$development$integration_client_secret"
      parser.environment.should == :development
    end

    it "raises error on inconsistent environment" do
      expect do
        Braintree::CredentialsParser.new(
          :client_id => "client_id$development$integration_client_id",
          :client_secret => "client_secret$qa$integration_client_secret",
        )
      end.to raise_error(Braintree::ConfigurationError, /Mismatched credential environments/)
    end

    it "raises error on missing client_id" do
      expect do
        Braintree::CredentialsParser.new(
          :client_secret => "client_secret$development$integration_client_secret",
        )
      end.to raise_error(Braintree::ConfigurationError, /Missing client_id/)
    end

    it "raises error on missing client_secret" do
      expect do
        Braintree::CredentialsParser.new(
          :client_id => "client_id$development$integration_client_id",
        )
      end.to raise_error(Braintree::ConfigurationError, /Missing client_secret/)
    end

    it "raises error on invalid client_id" do
      expect do
        Braintree::CredentialsParser.new(
          :client_id => "client_secret$development$integration_client_secret",
          :client_secret => "client_secret$development$integration_client_secret",
        )
      end.to raise_error(Braintree::ConfigurationError, /is not a client_id/)
    end

    it "raises error on invalid client_secret" do
      expect do
        Braintree::CredentialsParser.new(
          :client_id => "client_id$development$integration_client_id",
          :client_secret => "client_id$development$integration_client_id",
        )
      end.to raise_error(Braintree::ConfigurationError, /is not a client_secret/)
    end
  end
end
