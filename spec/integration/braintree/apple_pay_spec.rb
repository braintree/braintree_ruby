require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::ApplePayGateway do
  before(:each) do
    gateway = Braintree::Gateway.new(
      :client_id => "client_id$#{Braintree::Configuration.environment}$integration_client_id",
      :client_secret => "client_secret$#{Braintree::Configuration.environment}$integration_client_secret",
      :logger => Logger.new("/dev/null"),
    )

    result = gateway.merchant.create(
      :email => "name@email.com",
      :country_code_alpha3 => "GBR",
      :payment_methods => ["credit_card", "paypal"],
    )

    @gateway = Braintree::Gateway.new(
      :access_token => result.credentials.access_token,
      :logger => Logger.new("/dev/null"),
    )
  end

  describe "register_domain" do
    it "registers an apple pay domain" do
      result = @gateway.apple_pay.register_domain("www.example.com")
      expect(result).to be_success
    end

    it "gets a validation error when attempting to register no domains" do
      result = @gateway.apple_pay.register_domain("")
      expect(result).not_to be_success
      expect(result.errors.for(:apple_pay)[0].message).to eq("Domain name is required.")
    end
  end

  describe "unregister_domain" do
    it "unregisters an apple pay domain" do
      domain = "example.org"
      result = @gateway.apple_pay.unregister_domain(domain)
      expect(result).to be_success
    end

    it "unregisters an apple pay domain with scheme in url" do
      domain = "http://example.org"
      result = @gateway.apple_pay.unregister_domain(domain)
      expect(result).to be_success
    end

    it "escapes the unregistered domain query parameter" do
      domain = "ex&mple.org"
      result = @gateway.apple_pay.unregister_domain(domain)
      expect(result).to be_success
    end
  end

  describe "registered_domains" do
    it "returns stubbed registered domains" do
      result = @gateway.apple_pay.registered_domains
      expect(result).to be_success
      expect(result.apple_pay_options.domains).to eq(["www.example.com"])
    end
  end
end
