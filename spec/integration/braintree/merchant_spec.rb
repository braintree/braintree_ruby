require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::MerchantGateway do
  # NEXT_MAJOR_VERSION remove this test
  describe "create" do
    it "raises a server error because the endpoint has been disabled" do
      gateway = Braintree::Gateway.new(
        :client_id => "client_id$#{Braintree::Configuration.environment}$integration_client_id",
        :client_secret => "client_secret$#{Braintree::Configuration.environment}$integration_client_secret",
        :logger => Logger.new("/dev/null"),
      )

      expect do
        gateway.merchant.create(
          :email => "name@email.com",
          :country_code_alpha3 => "GBR",
          :payment_methods => ["credit_card", "paypal"],
        )
      end.to raise_error(Braintree::ServerError)
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
        expect(result).to be_success
        expect(result.supported_networks).to eq(["visa", "mastercard", "amex", "discover", "maestro", "elo"])
      end

      it "is repeatable" do
        result = Braintree::Merchant.provision_raw_apple_pay
        expect(result).to be_success
        result = Braintree::Merchant.provision_raw_apple_pay
        expect(result).to be_success
        expect(result.supported_networks).to eq(["visa", "mastercard", "amex", "discover", "maestro", "elo"])
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
