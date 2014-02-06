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
        :merchant_id => 'merchant_id',
        :public_key => 'public_key',
        :private_key => 'private_key'
      )

      config.merchant_id.should == 'merchant_id'
      config.public_key.should == 'public_key'
      config.private_key.should == 'private_key'
    end

    it "accepts partner credentials" do
      config = Braintree::Configuration.new(
        :partner_id => 'partner_id',
        :public_key => 'public_key',
        :private_key => 'private_key'
      )

      config.merchant_id.should == 'partner_id'
      config.public_key.should == 'public_key'
      config.private_key.should == 'private_key'
    end
  end

  describe "base_merchant_path" do
    it "returns /merchants/{merchant_id}" do
      Braintree::Configuration.instantiate.base_merchant_path.should == "/merchants/integration_merchant_id"
    end
  end

  describe "base_merchant_url" do
    it "returns the expected url for the development env" do
      Braintree::Configuration.environment = :development
      port = Braintree::Configuration.instantiate.port
      Braintree::Configuration.instantiate.base_merchant_url.should == "http://localhost:#{port}/merchants/integration_merchant_id"
    end

    it "returns the expected url for the sandbox env" do
      Braintree::Configuration.environment = :sandbox
      Braintree::Configuration.instantiate.base_merchant_url.should == "https://api.sandbox.braintreegateway.com:443/merchants/integration_merchant_id"
    end

    it "returns the expected url for the production env" do
      Braintree::Configuration.environment = :production
      Braintree::Configuration.instantiate.base_merchant_url.should == "https://api.braintreegateway.com:443/merchants/integration_merchant_id"
    end
  end

  describe "ca_file" do
    it "qa" do
      Braintree::Configuration.environment = :qa
      ca_file = Braintree::Configuration.instantiate.ca_file
      ca_file.should match(/api_braintreegateway_com\.ca\.crt$/)
      File.exists?(ca_file).should == true
    end

    it "sandbox" do
      Braintree::Configuration.environment = :sandbox
      ca_file = Braintree::Configuration.instantiate.ca_file
      ca_file.should match(/api_braintreegateway_com\.ca\.crt$/)
      File.exists?(ca_file).should == true
    end

    it "production" do
      Braintree::Configuration.environment = :production
      ca_file = Braintree::Configuration.instantiate.ca_file
      ca_file.should match(/api_braintreegateway_com\.ca\.crt$/)
      File.exists?(ca_file).should == true
    end
  end

  describe "logger" do
    it "defaults to logging to stdout with log_level info" do
      config = Braintree::Configuration.new
      config.logger.level.should == Logger::INFO
    end

    it "lazily initializes so that you can do Braintree::Configuration.logger.level = when configuring the client lib" do
      config = Braintree::Configuration.new :logger => nil
      config.logger.should_not == nil
    end
  end

  describe "self.environment" do
    it "raises an exception if it hasn't been set yet" do
      Braintree::Configuration.instance_variable_set(:@environment, nil)
      expect do
        Braintree::Configuration.environment
      end.to raise_error(Braintree::ConfigurationError, "Braintree::Configuration.environment needs to be set")
    end
  end

  describe "self.environment=" do
    it "raises an exception if the environment is invalid" do
      expect do
        Braintree::Configuration.environment = :invalid_environment
      end.to raise_error(ArgumentError, ":invalid_environment is not a valid environment")
    end
  end

  describe "self.logger" do
    it "defaults to logging to stdout with log_level info" do
      begin
        old_logger = Braintree::Configuration.logger
        Braintree::Configuration.logger = nil
        Braintree::Configuration.instantiate.logger.level.should == Logger::INFO
      ensure
        Braintree::Configuration.logger = old_logger
      end
    end

    it "lazily initializes so that you can do Braintree::Configuration.logger.level = when configuring the client lib" do
      Braintree::Configuration.logger = nil
      Braintree::Configuration.logger.should_not == nil
    end
  end

  describe "self.merchant_id" do
    it "raises an exception if it hasn't been set yet" do
      Braintree::Configuration.instance_variable_set(:@merchant_id, nil)
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
  end

  describe "self.private_key" do
    it "raises an exception if it hasn't been set yet" do
      Braintree::Configuration.instance_variable_set(:@private_key, nil)
      expect do
        Braintree::Configuration.private_key
      end.to raise_error(Braintree::ConfigurationError, "Braintree::Configuration.private_key needs to be set")
    end
  end

  describe "self.port" do
    it "is 443 for production" do
      Braintree::Configuration.environment = :production
      Braintree::Configuration.instantiate.port.should == 443
    end

    it "is 443 for sandbox" do
      Braintree::Configuration.environment = :sandbox
      Braintree::Configuration.instantiate.port.should == 443
    end

    it "is 3000 or GATEWAY_PORT environment variable for development" do
      Braintree::Configuration.environment = :development
      old_gateway_port = ENV['GATEWAY_PORT']
      begin
        ENV['GATEWAY_PORT'] = nil
        Braintree::Configuration.instantiate.port.should == 3000

        ENV['GATEWAY_PORT'] = '1234'
        Braintree::Configuration.instantiate.port.should == '1234'
      ensure
        ENV['GATEWAY_PORT'] = old_gateway_port
      end
    end
  end

  describe "self.protocol" do
    it "is http for development" do
      Braintree::Configuration.environment = :development
      Braintree::Configuration.instantiate.protocol.should == "http"
    end

    it "is https for production" do
      Braintree::Configuration.environment = :production
      Braintree::Configuration.instantiate.protocol.should == "https"
    end

    it "is https for sandbox" do
      Braintree::Configuration.environment = :sandbox
      Braintree::Configuration.instantiate.protocol.should == "https"
    end

  end

  describe "server" do
    it "is localhost for development" do
      Braintree::Configuration.environment = :development
      Braintree::Configuration.instantiate.server.should == "localhost"
    end

    it "is api.braintreegateway.com for production" do
      Braintree::Configuration.environment = :production
      Braintree::Configuration.instantiate.server.should == "api.braintreegateway.com"
    end

    it "is api.sandbox.braintreegateway.com for sandbox" do
      Braintree::Configuration.environment = :sandbox
      Braintree::Configuration.instantiate.server.should == "api.sandbox.braintreegateway.com"
    end

    it "is qa.braintreegateway.com for qa" do
      Braintree::Configuration.environment = :qa
      Braintree::Configuration.instantiate.server.should == "qa.braintreegateway.com"
    end

    it "can by changed by configuring the production endpoint" do
      Braintree::Configuration.environment = :production
      Braintree::Configuration.endpoint = "custom-endpoint"
      Braintree::Configuration.instantiate.server.should == "custom-endpoint.braintreegateway.com"
    end
  end

  describe "auth_url" do
    it "is http://auth.venmo.dev for development" do
      Braintree::Configuration.environment = :development
      Braintree::Configuration.instantiate.auth_url.should == "http://auth.venmo.dev:9292"
    end

    it "is https://auth.venmo.com for production" do
      Braintree::Configuration.environment = :production
      Braintree::Configuration.instantiate.auth_url.should == "https://auth.venmo.com"
    end

    it "is https://auth.sandbox.venmo.com for sandbox" do
      Braintree::Configuration.environment = :sandbox
      Braintree::Configuration.instantiate.auth_url.should == "https://auth.venmo.sandbox.braintreegateway.com"
    end

    it "is https://auth.qa.venmo.com for qa" do
      Braintree::Configuration.environment = :qa
      Braintree::Configuration.instantiate.auth_url.should == "https://auth.venmo.qa2.braintreegateway.com"
    end
  end

  describe "ssl?" do
    it "returns false for development" do
      Braintree::Configuration.environment = :development
      Braintree::Configuration.instantiate.ssl?.should == false
    end

    it "returns true for production" do
      Braintree::Configuration.environment = :production
      Braintree::Configuration.instantiate.ssl?.should == true
    end

    it "returns true for sandbox" do
      Braintree::Configuration.environment = :sandbox
      Braintree::Configuration.instantiate.ssl?.should == true
    end
  end

  describe "user_agent" do
    after :each do
      Braintree::Configuration.custom_user_agent = nil
    end

    it "appends the default user_agent with the given value" do
      Braintree::Configuration.custom_user_agent = "ActiveMerchant 1.2.3"
      Braintree::Configuration.instantiate.user_agent.should == "Braintree Ruby Gem #{Braintree::Version::String} (ActiveMerchant 1.2.3)"
    end

    it "does not append anything if there is no custom_user_agent" do
      Braintree::Configuration.custom_user_agent = nil
      Braintree::Configuration.instantiate.user_agent.should == "Braintree Ruby Gem #{Braintree::Version::String}"
    end
  end

  describe "inspect" do
    it "masks the private_key" do
      config = Braintree::Configuration.new(:private_key => "secret_key")
      config.inspect.should include('@private_key="[FILTERED]"')
      config.inspect.should_not include('secret_key')
    end
  end

  describe "signature_service" do
    it "has a signature service initialized with the private key" do
      config = Braintree::Configuration.new(:private_key => "secret_key")

      config.signature_service.key.should == "secret_key"
    end
  end
end
