require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::MerchantGateway do
  describe "create" do
    it "creates a merchant" do
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

      expect(result).to be_success

      merchant = result.merchant
      expect(merchant.id).not_to be_nil
      expect(merchant.email).to eq("name@email.com")
      expect(merchant.company_name).to eq("name@email.com")
      expect(merchant.country_code_alpha3).to eq("GBR")
      expect(merchant.country_code_alpha2).to eq("GB")
      expect(merchant.country_code_numeric).to eq("826")
      expect(merchant.country_name).to eq("United Kingdom")

      credentials = result.credentials
      expect(credentials.access_token).not_to be_nil
      expect(credentials.refresh_token).not_to be_nil
      expect(credentials.expires_at).not_to be_nil
      expect(credentials.token_type).to eq("bearer")
    end

    it "gives an error when using invalid payment_methods" do
      gateway = Braintree::Gateway.new(
        :client_id => "client_id$#{Braintree::Configuration.environment}$integration_client_id",
        :client_secret => "client_secret$#{Braintree::Configuration.environment}$integration_client_secret",
        :logger => Logger.new("/dev/null"),
      )

      result = gateway.merchant.create(
        :email => "name@email.com",
        :country_code_alpha3 => "GBR",
        :payment_methods => ["fake_money"],
      )

      expect(result).not_to be_success
      errors = result.errors.for(:merchant).on(:payment_methods)

      expect(errors[0].code).to eq(Braintree::ErrorCodes::Merchant::PaymentMethodsAreInvalid)
    end

    context "credentials" do
      around(:each) do |example|
        old_merchant_id_value = Braintree::Configuration.merchant_id
        example.run
        Braintree::Configuration.merchant_id = old_merchant_id_value
      end

      it "allows using a merchant_id passed in through Gateway" do
        Braintree::Configuration.merchant_id = nil

        gateway = Braintree::Gateway.new(
          :client_id => "client_id$#{Braintree::Configuration.environment}$integration_client_id",
          :client_secret => "client_secret$#{Braintree::Configuration.environment}$integration_client_secret",
          :merchant_id => "integration_merchant_id",
          :logger => Logger.new("/dev/null"),
        )
        result = gateway.merchant.create(
          :email => "name@email.com",
          :country_code_alpha3 => "GBR",
          :payment_methods => ["credit_card", "paypal"],
        )

        expect(result).to be_success
      end
    end

    context "multiple currencies" do
      before(:each) do
        @gateway = Braintree::Gateway.new(
          :client_id => "client_id$#{Braintree::Configuration.environment}$integration_client_id",
          :client_secret => "client_secret$#{Braintree::Configuration.environment}$integration_client_secret",
          :logger => Logger.new("/dev/null"),
        )
      end

      it "creates an EU multi currency merchant for paypal and credit_card" do
        result = @gateway.merchant.create(
          :email => "name@email.com",
          :country_code_alpha3 => "GBR",
          :payment_methods => ["credit_card", "paypal"],
          :currencies => ["GBP", "USD"],
        )

        merchant = result.merchant
        expect(merchant.id).not_to be_nil
        expect(merchant.email).to eq("name@email.com")
        expect(merchant.company_name).to eq("name@email.com")
        expect(merchant.country_code_alpha3).to eq("GBR")
        expect(merchant.country_code_alpha2).to eq("GB")
        expect(merchant.country_code_numeric).to eq("826")
        expect(merchant.country_name).to eq("United Kingdom")

        credentials = result.credentials
        expect(credentials.access_token).not_to be_nil
        expect(credentials.refresh_token).not_to be_nil
        expect(credentials.expires_at).not_to be_nil
        expect(credentials.token_type).to eq("bearer")

        merchant_accounts = merchant.merchant_accounts
        expect(merchant_accounts.count).to eq(2)

        merchant_account = merchant_accounts.detect { |ma| ma.id == "GBP" }
        expect(merchant_account.default).to eq(true)
        expect(merchant_account.currency_iso_code).to eq("GBP")

        merchant_account = merchant_accounts.detect { |ma| ma.id == "USD" }
        expect(merchant_account.default).to eq(false)
        expect(merchant_account.currency_iso_code).to eq("USD")
      end


      it "creates a paypal-only merchant that accepts multiple currencies" do
        result = @gateway.merchant.create(
          :email => "name@email.com",
          :country_code_alpha3 => "GBR",
          :payment_methods => ["paypal"],
          :currencies => ["GBP", "USD"],
          :paypal_account => {
            :client_id => "paypal_client_id",
            :client_secret => "paypal_client_secret",
          },
        )

        expect(result).to be_success

        merchant = result.merchant
        expect(merchant.id).not_to be_nil
        expect(merchant.email).to eq("name@email.com")
        expect(merchant.company_name).to eq("name@email.com")
        expect(merchant.country_code_alpha3).to eq("GBR")
        expect(merchant.country_code_alpha2).to eq("GB")
        expect(merchant.country_code_numeric).to eq("826")
        expect(merchant.country_name).to eq("United Kingdom")

        credentials = result.credentials
        expect(credentials.access_token).not_to be_nil
        expect(credentials.refresh_token).not_to be_nil
        expect(credentials.expires_at).not_to be_nil
        expect(credentials.token_type).to eq("bearer")

        merchant_accounts = merchant.merchant_accounts
        expect(merchant_accounts.count).to eq(2)

        merchant_account = merchant_accounts.detect { |ma| ma.id == "USD" }
        expect(merchant_account.default).to eq(false)
        expect(merchant_account.currency_iso_code).to eq("USD")

        merchant_account = merchant_accounts.detect { |ma| ma.id == "GBP" }
        expect(merchant_account.default).to eq(true)
        expect(merchant_account.currency_iso_code).to eq("GBP")
      end

      it "returns error if invalid currency is passed" do
        result = @gateway.merchant.create(
          :email => "name@email.com",
          :country_code_alpha3 => "GBR",
          :payment_methods => ["paypal"],
          :currencies => ["FAKE", "GBP"],
          :paypal_account => {
            :client_id => "paypal_client_id",
            :client_secret => "paypal_client_secret",
          },
        )

        expect(result).not_to be_success
        errors = result.errors.for(:merchant).on(:currencies)

        expect(errors[0].code).to eq(Braintree::ErrorCodes::Merchant::CurrenciesAreInvalid)
      end
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
