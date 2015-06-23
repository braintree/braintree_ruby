require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::MerchantGateway do
  describe "create" do
    it "creates a merchant" do
      gateway = Braintree::Gateway.new(
        :client_id => "client_id$development$integration_client_id",
        :client_secret => "client_secret$development$integration_client_secret",
        :logger => Logger.new("/dev/null")
      )

      result = gateway.merchant.create(
        :email => "name@email.com",
        :country_code_alpha3 => "USA",
        :payment_methods => ["credit_card", "paypal"]
      )

      result.should be_success

      merchant = result.merchant
      merchant.id.should_not be_nil
      merchant.email.should == "name@email.com"
      merchant.company_name.should == "name@email.com"
      merchant.country_code_alpha3.should == "USA"
      merchant.country_code_alpha2.should == "US"
      merchant.country_code_numeric.should == "840"
      merchant.country_name.should == "United States of America"

      credentials = result.credentials
      credentials.access_token.should start_with("access_token$")
      credentials.expires_at.should_not be_nil
      credentials.token_type.should == "bearer"
      credentials.refresh_token.should be_nil
    end

    it "gives an error when using invalid payment_methods" do
      gateway = Braintree::Gateway.new(
        :client_id => "client_id$development$integration_client_id",
        :client_secret => "client_secret$development$integration_client_secret",
        :logger => Logger.new("/dev/null")
      )

      result = gateway.merchant.create(
        :email => "name@email.com",
        :country_code_alpha3 => "USA",
        :payment_methods => ["fake_money"]
      )

      result.should_not be_success
      errors = result.errors.for(:merchant).on(:payment_methods)

      errors[0].code.should == Braintree::ErrorCodes::Merchant::PaymentMethodsAreInvalid
    end
  end
end
