require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::ApplePayGateway do
  before(:each) do
    gateway = Braintree::Gateway.new(
      :client_id => "client_id$#{Braintree::Configuration.environment}$integration_client_id",
      :client_secret => "client_secret$#{Braintree::Configuration.environment}$integration_client_secret",
      :logger => Logger.new("/dev/null")
    )

    result = gateway.merchant.create(
      :email => "name@email.com",
      :country_code_alpha3 => "USA",
      :payment_methods => ["credit_card", "paypal"]
    )

    @gateway = Braintree::Gateway.new(
      :access_token => result.credentials.access_token,
      :logger => Logger.new("/dev/null")
    )
  end

  describe "register_domain" do
    it "registers an apple pay domain" do
      result = @gateway.apple_pay.register_domain("www.example.com")
      result.should be_success
    end

    it "gets a validation error when attempting to register no domains" do
      result = @gateway.apple_pay.register_domain("")
      result.should_not be_success
      result.errors.for(:apple_pay)[0].message.should eq("Domain name is required.")
    end
  end

  describe "unregister_domain" do
    it "unregisters an apple pay domain" do
      domain = "example.org"
      result = @gateway.apple_pay.register_domain(domain)
      result.should be_success

      result = @gateway.apple_pay.unregister_domain(domain)
      result.should be_success
      @gateway.apple_pay.registered_domains.apple_pay_options.domains.should be_empty
    end

    it "does not fail when unregistering a non-registered domain" do
      result = @gateway.apple_pay.unregister_domain("unregistered.com")
      result.should be_success
    end

    it "escapes the unregistered domain query parameter" do
      domain = "ex&mple.org"
      result = @gateway.apple_pay.register_domain(domain)
      result.should be_success
      @gateway.apple_pay.registered_domains.apple_pay_options.domains.should_not be_empty

      result = @gateway.apple_pay.unregister_domain(domain)
      result.should be_success
      @gateway.apple_pay.registered_domains.apple_pay_options.domains.should be_empty
    end
  end

  describe "registered_domains" do
    it "returns registered domains" do
      result = @gateway.apple_pay.register_domain("www.example.com")
      result.should be_success
      result = @gateway.apple_pay.register_domain("www.example.org")
      result.should be_success

      result = @gateway.apple_pay.registered_domains
      result.should be_success
      result.apple_pay_options.domains.should =~ ["www.example.org", "www.example.com"]
    end

    it "returns an empty list if no domains are registered" do
      result = @gateway.apple_pay.registered_domains
      result.should be_success
      result.apple_pay_options.domains.should == []
    end
  end
end
