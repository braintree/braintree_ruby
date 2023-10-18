require "stringio"

require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Configuration do

  before do
    @original_merchant_id = Braintree::Configuration.merchant_id
    @original_public_key = Braintree::Configuration.public_key
    @original_private_key = Braintree::Configuration.private_key
    @original_environment = Braintree::Configuration.environment
  end

  after do
    Braintree::Configuration.merchant_id = @original_merchant_id
    Braintree::Configuration.public_key = @original_public_key
    Braintree::Configuration.private_key = @original_private_key
    Braintree::Configuration.environment = @original_environment
    Braintree::Configuration.endpoint = Braintree::Configuration::DEFAULT_ENDPOINT
  end

  describe "initialize" do
    it "accepts merchant credentials" do
      config = Braintree::Configuration.new(
        :merchant_id => "merchant_id",
        :public_key => "public_key",
        :private_key => "private_key",
      )

      expect(config.merchant_id).to eq("merchant_id")
      expect(config.public_key).to eq("public_key")
      expect(config.private_key).to eq("private_key")
    end

    it "accepts partner credentials" do
      config = Braintree::Configuration.new(
        :partner_id => "partner_id",
        :public_key => "public_key",
        :private_key => "private_key",
      )

      expect(config.merchant_id).to eq("partner_id")
      expect(config.public_key).to eq("public_key")
      expect(config.private_key).to eq("private_key")
    end

    it "raises if combining client_id/secret with access_token" do
      expect do
        Braintree::Configuration.new(
          :client_id => "client_id$development$integration_client_id",
          :client_secret => "client_secret$development$integration_client_secret",
          :access_token => "access_token$development$integration_merchant_id$fb27c79dd",
        )
      end.to raise_error(Braintree::ConfigurationError, /mixed credential types/)
    end

    it "raises if combining client_id/secret with public_key/private_key" do
      expect do
        Braintree::Configuration.new(
          :client_id => "client_id$development$integration_client_id",
          :client_secret => "client_secret$development$integration_client_secret",
          :merchant_id => "merchant_id",
          :public_key => "public_key",
          :private_key => "private_key",
          :environment => "development",
        )
      end.to raise_error(Braintree::ConfigurationError, /mixed credential types/)
    end

    context "mixed environments" do
      before do
        @original_stderr = $stderr
        $stderr = StringIO.new
      end

      after do
        $stderr = @original_stderr
      end

      it "warns if both environment and access_token are provided and their environments differ" do
        Braintree::Configuration.new(
          :access_token => "access_token$development$integration_merchant_id$fb27c79dd",
          :environment => "sandbox",
        )
        expect($stderr.string).to eq("Braintree::Gateway should not be initialized with mixed environments: environment parameter and access_token do not match, environment from access_token is used.\n")
      end

      it "does not warn if both environment and access_token are provided and their environments match" do
        Braintree::Configuration.new(
          :access_token => "access_token$development$integration_merchant_id$fb27c79dd",
          :environment => "development",
        )
        expect($stderr.string).to eq("")
      end
    end

    it "accepts proxy params" do
      config = Braintree::Configuration.new(
        :proxy_address => "localhost",
        :proxy_port => 8080,
        :proxy_user => "user",
        :proxy_pass => "test",
      )

      expect(config.proxy_address).to eq("localhost")
      expect(config.proxy_port).to eq(8080)
      expect(config.proxy_user).to eq("user")
      expect(config.proxy_pass).to eq("test")
    end

    it "accepts ssl version" do
      config = Braintree::Configuration.new(
        :ssl_version => :TLSv1_2,
      )

      expect(config.ssl_version).to eq(:TLSv1_2)
    end
  end

  describe "base_merchant_path" do
    it "returns /merchants/{merchant_id}" do
      expect(Braintree::Configuration.instantiate.base_merchant_path).to eq("/merchants/integration_merchant_id")
    end
  end

  describe "base_merchant_url" do
    it "returns the expected url for the development env" do
      Braintree::Configuration.environment = :development
      port = Braintree::Configuration.instantiate.port
      expect(Braintree::Configuration.instantiate.base_merchant_url).to eq("http://localhost:#{port}/merchants/integration_merchant_id")
    end

    it "returns the expected url for the sandbox env" do
      Braintree::Configuration.environment = :sandbox
      expect(Braintree::Configuration.instantiate.base_merchant_url).to eq("https://api.sandbox.braintreegateway.com:443/merchants/integration_merchant_id")
    end

    it "returns the expected url for the production env" do
      Braintree::Configuration.environment = :production
      expect(Braintree::Configuration.instantiate.base_merchant_url).to eq("https://api.braintreegateway.com:443/merchants/integration_merchant_id")
    end
  end

  describe "ca_file" do
    it "sandbox" do
      Braintree::Configuration.environment = :sandbox
      ca_file = Braintree::Configuration.instantiate.ca_file
      expect(ca_file).to match(/api_braintreegateway_com\.ca\.crt$/)
      expect(File.exist?(ca_file)).to eq(true)
    end

    it "production" do
      Braintree::Configuration.environment = :production
      ca_file = Braintree::Configuration.instantiate.ca_file
      expect(ca_file).to match(/api_braintreegateway_com\.ca\.crt$/)
      expect(File.exist?(ca_file)).to eq(true)
    end
  end

  describe "logger" do
    it "defaults to logging to stdout with log_level info" do
      config = Braintree::Configuration.new
      expect(config.logger.level).to eq(Logger::INFO)
    end

    it "lazily initializes so that you can do Braintree::Configuration.logger.level = when configuring the client lib" do
      config = Braintree::Configuration.new :logger => nil
      expect(config.logger).not_to eq(nil)
    end

    it "can set logger on gateway instance" do
      gateway = Braintree::Configuration.gateway
      old_logger = Braintree::Configuration.logger

      new_logger = Logger.new("/dev/null")

      gateway.config.logger = new_logger

      expect(gateway.config.logger).to eq(new_logger)

      gateway.config.logger = old_logger
    end
  end

  describe "self.environment" do
    it "raises an exception if it hasn't been set yet" do
      Braintree::Configuration.instance_variable_set(:@environment, nil)
      expect do
        Braintree::Configuration.environment
      end.to raise_error(Braintree::ConfigurationError, "Braintree::Configuration.environment needs to be set")
    end

    it "raises an exception if it is an empty string" do
      Braintree::Configuration.instance_variable_set(:@environment, "")
      expect do
        Braintree::Configuration.environment
      end.to raise_error(Braintree::ConfigurationError, "Braintree::Configuration.environment needs to be set")
    end

    it "converts environment to symbol" do
      config = Braintree::Configuration.new({
        :environment => "sandbox"
      })

      expect(config.environment).to eq(:sandbox)
    end
  end

  describe "self.gateway" do
    it "sets its proxy config" do
      Braintree::Configuration.proxy_address = "localhost"
      Braintree::Configuration.proxy_port = 8080
      Braintree::Configuration.proxy_user = "user"
      Braintree::Configuration.proxy_pass = "test"

      gateway = Braintree::Configuration.gateway

      expect(gateway.config.proxy_address).to eq("localhost")
      expect(gateway.config.proxy_port).to eq(8080)
      expect(gateway.config.proxy_user).to eq("user")
      expect(gateway.config.proxy_pass).to eq("test")
    end

    it "sets the ssl version" do
      Braintree::Configuration.ssl_version = :TLSv1_2
      gateway = Braintree::Configuration.gateway

      expect(gateway.config.ssl_version).to eq(:TLSv1_2)
    end
  end

  describe "self.environment=" do
    it "raises an exception if the environment is invalid" do
      expect do
        Braintree::Configuration.environment = :invalid_environment
      end.to raise_error(ArgumentError, ":invalid_environment is not a valid environment")
    end

    it "allows the environment to be set with a string value" do
      expect do
        Braintree::Configuration.environment = "sandbox"
      end.not_to raise_error
    end

    it "sets the environment as a symbol" do
      Braintree::Configuration.environment = "sandbox"
      expect(Braintree::Configuration.environment).to eq :sandbox
    end
  end

  describe "self.logger" do
    it "defaults to logging to stdout with log_level info" do
      begin
        old_logger = Braintree::Configuration.logger
        Braintree::Configuration.logger = nil
        expect(Braintree::Configuration.instantiate.logger.level).to eq(Logger::INFO)
      ensure
        Braintree::Configuration.logger = old_logger
      end
    end

    it "lazily initializes so that you can do Braintree::Configuration.logger.level = when configuring the client lib" do
      Braintree::Configuration.logger = nil
      expect(Braintree::Configuration.logger).not_to eq(nil)
    end
  end

  describe "self.merchant_id" do
    it "raises an exception if it hasn't been set yet" do
      Braintree::Configuration.instance_variable_set(:@merchant_id, nil)
      expect do
        Braintree::Configuration.merchant_id
      end.to raise_error(Braintree::ConfigurationError, "Braintree::Configuration.merchant_id needs to be set")
    end

    it "raises an exception if it is an empty string" do
      Braintree::Configuration.instance_variable_set(:@merchant_id, "")
      expect do
        Braintree::Configuration.merchant_id
      end.to raise_error(Braintree::ConfigurationError, "Braintree::Configuration.merchant_id needs to be set")
    end
  end

  describe "self.public_key" do
    it "raises an exception if it hasn't been set yet" do
      Braintree::Configuration.instance_variable_set(:@public_key, nil)
      expect do
        Braintree::Configuration.public_key
      end.to raise_error(Braintree::ConfigurationError, "Braintree::Configuration.public_key needs to be set")
    end

    it "raises an exception if it is an empty string" do
      Braintree::Configuration.instance_variable_set(:@public_key, "")
      expect do
        Braintree::Configuration.public_key
      end.to raise_error(Braintree::ConfigurationError, "Braintree::Configuration.public_key needs to be set")
    end
  end

  describe "self.private_key" do
    it "raises an exception if it hasn't been set yet" do
      Braintree::Configuration.instance_variable_set(:@private_key, nil)
      expect do
        Braintree::Configuration.private_key
      end.to raise_error(Braintree::ConfigurationError, "Braintree::Configuration.private_key needs to be set")
    end

    it "raises an exception if it is an empty string" do
      Braintree::Configuration.instance_variable_set(:@private_key, "")
      expect do
        Braintree::Configuration.private_key
      end.to raise_error(Braintree::ConfigurationError, "Braintree::Configuration.private_key needs to be set")
    end
  end

  describe "self.port" do
    it "is 443 for production" do
      Braintree::Configuration.environment = :production
      expect(Braintree::Configuration.instantiate.port).to eq(443)
    end

    it "is 443 for sandbox" do
      Braintree::Configuration.environment = :sandbox
      expect(Braintree::Configuration.instantiate.port).to eq(443)
    end

    it "is 3000 or GATEWAY_PORT environment variable for development" do
      Braintree::Configuration.environment = :development
      old_gateway_port = ENV["GATEWAY_PORT"]
      begin
        ENV["GATEWAY_PORT"] = nil
        expect(Braintree::Configuration.instantiate.port).to eq(3000)

        ENV["GATEWAY_PORT"] = "1234"
        expect(Braintree::Configuration.instantiate.port).to eq("1234")
      ensure
        ENV["GATEWAY_PORT"] = old_gateway_port
      end
    end
  end

  describe "self.protocol" do
    it "is http for development" do
      Braintree::Configuration.environment = :development
      expect(Braintree::Configuration.instantiate.protocol).to eq("http")
    end

    it "is https for production" do
      Braintree::Configuration.environment = :production
      expect(Braintree::Configuration.instantiate.protocol).to eq("https")
    end

    it "is https for sandbox" do
      Braintree::Configuration.environment = :sandbox
      expect(Braintree::Configuration.instantiate.protocol).to eq("https")
    end
  end

  describe "graphql_server" do
    it "is localhost or GRAPHQL_HOST environment variable for development" do
      Braintree::Configuration.environment = :development
      old_gateway_url = ENV["GRAPHQL_HOST"]
      begin
        ENV["GRAPHQL_HOST"] = nil
        expect(Braintree::Configuration.instantiate.graphql_server).to eq("graphql.bt.local")

        ENV["GRAPHQL_HOST"] = "gateway"
        expect(Braintree::Configuration.instantiate.graphql_server).to eq("gateway")
      ensure
        ENV["GRAPHQL_HOST"] = old_gateway_url
      end
    end
  end

  describe "server" do
    it "is localhost or GATEWAY_HOST environment variable for development" do
      Braintree::Configuration.environment = :development
      old_gateway_url = ENV["GATEWAY_HOST"]
      begin
        ENV["GATEWAY_HOST"] = nil
        expect(Braintree::Configuration.instantiate.server).to eq("localhost")

        ENV["GATEWAY_HOST"] = "gateway"
        expect(Braintree::Configuration.instantiate.server).to eq("gateway")
      ensure
        ENV["GATEWAY_HOST"] = old_gateway_url
      end
    end

    it "is api.braintreegateway.com for production" do
      Braintree::Configuration.environment = :production
      expect(Braintree::Configuration.instantiate.server).to eq("api.braintreegateway.com")
    end

    it "is api.sandbox.braintreegateway.com for sandbox" do
      Braintree::Configuration.environment = :sandbox
      expect(Braintree::Configuration.instantiate.server).to eq("api.sandbox.braintreegateway.com")
    end

    it "is qa.braintreegateway.com for qa" do
      Braintree::Configuration.environment = :qa
      expect(Braintree::Configuration.instantiate.server).to eq("gateway.qa.braintreepayments.com")
    end

    it "can by changed by configuring the production endpoint" do
      Braintree::Configuration.environment = :production
      Braintree::Configuration.endpoint = "custom-endpoint"
      expect(Braintree::Configuration.instantiate.server).to eq("custom-endpoint.braintreegateway.com")
    end
  end

  describe "auth_url" do
    it "is http://auth.venmo.dev for development" do
      Braintree::Configuration.environment = :development
      expect(Braintree::Configuration.instantiate.auth_url).to eq("http://auth.venmo.dev:9292")
    end

    it "is https://auth.venmo.com for production" do
      Braintree::Configuration.environment = :production
      expect(Braintree::Configuration.instantiate.auth_url).to eq("https://auth.venmo.com")
    end

    it "is https://auth.sandbox.venmo.com for sandbox" do
      Braintree::Configuration.environment = :sandbox
      expect(Braintree::Configuration.instantiate.auth_url).to eq("https://auth.venmo.sandbox.braintreegateway.com")
    end

    it "is https://auth.qa.venmo.com for qa" do
      Braintree::Configuration.environment = :qa
      expect(Braintree::Configuration.instantiate.auth_url).to eq("https://auth.venmo.qa2.braintreegateway.com")
    end
  end

  describe "ssl?" do
    it "returns false for development" do
      Braintree::Configuration.environment = :development
      expect(Braintree::Configuration.instantiate.ssl?).to eq(false)
    end

    it "returns true for production" do
      Braintree::Configuration.environment = :production
      expect(Braintree::Configuration.instantiate.ssl?).to eq(true)
    end

    it "returns true for sandbox" do
      Braintree::Configuration.environment = :sandbox
      expect(Braintree::Configuration.instantiate.ssl?).to eq(true)
    end
  end

  describe "user_agent" do
    after :each do
      Braintree::Configuration.custom_user_agent = nil
    end

    it "appends the default user_agent with the given value" do
      Braintree::Configuration.custom_user_agent = "ActiveMerchant 1.2.3"
      expect(Braintree::Configuration.instantiate.user_agent).to eq("Braintree Ruby Gem #{Braintree::Version::String} (ActiveMerchant 1.2.3)")
    end

    it "does not append anything if there is no custom_user_agent" do
      Braintree::Configuration.custom_user_agent = nil
      expect(Braintree::Configuration.instantiate.user_agent).to eq("Braintree Ruby Gem #{Braintree::Version::String}")
    end
  end

  describe "inspect" do
    it "masks the private_key" do
      config = Braintree::Configuration.new(:private_key => "secret_key")
      expect(config.inspect).to include('@private_key="[FILTERED]"')
      expect(config.inspect).not_to include("secret_key")
    end
  end

  describe "signature_service" do
    it "has a signature service initialized with the private key" do
      config = Braintree::Configuration.new(:private_key => "secret_key")

      expect(config.signature_service.key).to eq("secret_key")
    end
  end
end
