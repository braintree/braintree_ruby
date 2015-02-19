require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::Merchant do
  before { _save_config }
  after { _restore_config }

  describe "provision_raw_apple_pay" do
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
