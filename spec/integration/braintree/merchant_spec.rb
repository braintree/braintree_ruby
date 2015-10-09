require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

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

  describe "provision_raw_apple_pay" do
    before { _save_config }
    after { _restore_config }

    context "merchant has processor connection supporting apple pay" do
      before do
        Braintree::Configuration.merchant_id = "integration_merchant_id"
        Braintree::Configuration.public_key = "integration_public_key"
        Braintree::Configuration.private_key = "integration_private_key"
      end

      it "succeeds" do
        result = Braintree::Merchant.provision_raw_apple_pay
        result.should be_success
        result.supported_networks.should == ["visa", "mastercard", "amex"]
      end

      it "is repeatable" do
        result = Braintree::Merchant.provision_raw_apple_pay
        result.should be_success
        result = Braintree::Merchant.provision_raw_apple_pay
        result.should be_success
        result.supported_networks.should == ["visa", "mastercard", "amex"]
      end
    end

    context "merchant has no processor connection supporting apple pay" do
      before do
        Braintree::Configuration.merchant_id = "forward_payment_method_merchant_id"
        Braintree::Configuration.public_key = "forward_payment_method_public_key"
        Braintree::Configuration.private_key = "forward_payment_method_private_key"
      end

      it "returns a validation error" do
        result = Braintree::Merchant.provision_raw_apple_pay
        result.should_not be_success
        result.errors.for(:apple_pay).first.code.should == Braintree::ErrorCodes::ApplePay::ApplePayCardsAreNotAccepted
      end
    end

    def _save_config
      @original_config = {
        :merchant_id => Braintree::Configuration.merchant_id,
        :public_key => Braintree::Configuration.public_key,
        :private_key => Braintree::Configuration.private_key,
      }
    end

    def _restore_config
      Braintree::Configuration.merchant_id = @original_config[:merchant_id]
      Braintree::Configuration.public_key = @original_config[:public_key]
      Braintree::Configuration.private_key = @original_config[:private_key]
    end
  end
end
