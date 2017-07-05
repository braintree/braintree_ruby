require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::ApplePayGateway do
  describe "register_domain" do
    it "registers an apple pay domain" do
      result = Braintree::ApplePay.register_domain("www.example.com")
      result.should be_success
    end

    it "gets a validation error when attempting to register no domains" do
      result = Braintree::ApplePay.register_domain("")
      result.should_not be_success
      result.errors.for(:apple_pay)[0].message.should eq("Domain name is required.")
    end
  end
end
