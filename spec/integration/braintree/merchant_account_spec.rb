require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

DEPRECATED_APPLICATION_PARAMS = {
  :applicant_details => {
    :first_name => "Joe",
    :last_name => "Bloggs",
    :email => "joe@bloggs.com",
    :phone => "3125551234",
    :address => {
      :street_address => "123 Credibility St.",
      :postal_code => "60606",
      :locality => "Chicago",
      :region => "IL",
    },
    :date_of_birth => "10/9/1980",
    :ssn => "123-00-1234",
    :routing_number => "011103093",
    :account_number => "43759348798",
    :tax_id => "111223333",
    :company_name => "Joe's Junkyard"
  },
  :tos_accepted => true,
  :master_merchant_account_id => "sandbox_master_merchant_account"
}

VALID_APPLICATION_PARAMS = {
  :individual => {
    :first_name => "Joe",
    :last_name => "Bloggs",
    :email => "joe@bloggs.com",
    :phone => "3125551234",
    :address => {
      :street_address => "123 Credibility St.",
      :postal_code => "60606",
      :locality => "Chicago",
      :region => "IL",
    },
    :date_of_birth => "10/9/1980",
    :ssn => "123-00-1234",
  },
  :business => {
    :legal_name => "Joe's Bloggs",
    :dba_name => "Joe's Junkyard",
    :tax_id => "423456789",
    :address => {
      :street_address => "456 Fake St",
      :postal_code => "48104",
      :locality => "Ann Arbor",
      :region => "MI",
    }
  },
  :funding => {
    :destination => Braintree::MerchantAccount::FundingDestination::Bank,
    :routing_number => "011103093",
    :account_number => "43759348798",
    :descriptor => "Joes Bloggs MI",
  },
  :tos_accepted => true,
  :master_merchant_account_id => "sandbox_master_merchant_account"
}

describe Braintree::MerchantAccount do
  describe "all" do
    it "returns all merchant accounts" do
      gateway = Braintree::Gateway.new(
        :client_id => "client_id$#{Braintree::Configuration.environment}$integration_client_id",
        :client_secret => "client_secret$#{Braintree::Configuration.environment}$integration_client_secret",
        :logger => Logger.new("/dev/null"),
      )

      code = Braintree::OAuthTestHelper.create_grant(gateway, {
        :merchant_public_id => "integration_merchant_id",
        :scope => "read_write"
      })

      result = gateway.oauth.create_token_from_code(
        :code => code,
        :scope => "read_write",
      )

      gateway = Braintree::Gateway.new(
        :access_token => result.credentials.access_token,
        :logger => Logger.new("/dev/null"),
      )

      result = gateway.merchant_account.all
      expect(result).to be_success
      expect(result.merchant_accounts.count).to be > 20
    end

    it "returns merchant account with correct attributes" do
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

      gateway = Braintree::Gateway.new(
        :access_token => result.credentials.access_token,
        :logger => Logger.new("/dev/null"),
      )

      result = gateway.merchant_account.all
      expect(result).to be_success
      expect(result.merchant_accounts.count).to eq(1)
      expect(result.merchant_accounts.first.currency_iso_code).to eq("GBP")
      expect(result.merchant_accounts.first.status).to eq("active")
      expect(result.merchant_accounts.first.default).to eq(true)
    end

    it "returns all merchant accounts for read_only scoped grants" do
      gateway = Braintree::Gateway.new(
        :client_id => "client_id$#{Braintree::Configuration.environment}$integration_client_id",
        :client_secret => "client_secret$#{Braintree::Configuration.environment}$integration_client_secret",
        :logger => Logger.new("/dev/null"),
      )

      code = Braintree::OAuthTestHelper.create_grant(gateway, {
        :merchant_public_id => "integration_merchant_id",
        :scope => "read_only"
      })

      result = gateway.oauth.create_token_from_code(
        :code => code,
        :scope => "read_only",
      )

      gateway = Braintree::Gateway.new(
        :access_token => result.credentials.access_token,
        :logger => Logger.new("/dev/null"),
      )

      result = gateway.merchant_account.all
      expect(result).to be_success
      expect(result.merchant_accounts.count).to be > 20
    end
  end

  describe "create_for_currency" do
    it "creates a new merchant account for currency" do
      result = SpecHelper::create_merchant
      expect(result).to be_success

      gateway = Braintree::Gateway.new(
        :access_token => result.credentials.access_token,
        :logger => Logger.new("/dev/null"),
      )

      result = gateway.merchant_account.create_for_currency(
        :currency => "JPY",
      )
      expect(result).to be_success
      expect(result.merchant_account.currency_iso_code).to eq("JPY")
    end

    it "returns error if a merchant account already exists for that currency" do
      result = SpecHelper::create_merchant
      expect(result).to be_success

      gateway = Braintree::Gateway.new(
        :access_token => result.credentials.access_token,
        :logger => Logger.new("/dev/null"),
      )

      result = gateway.merchant_account.create_for_currency(
        :currency => "USD",
      )
      expect(result).to be_success

      result = gateway.merchant_account.create_for_currency(
        :currency => "USD",
      )
      expect(result).not_to be_success

      errors = result.errors.for(:merchant).on(:currency)
      expect(errors[0].code).to eq(Braintree::ErrorCodes::Merchant::MerchantAccountExistsForCurrency)
    end

    it "returns error if no currency is provided" do
      result = SpecHelper::create_merchant
      expect(result).to be_success

      gateway = Braintree::Gateway.new(
        :access_token => result.credentials.access_token,
        :logger => Logger.new("/dev/null"),
      )

      result = gateway.merchant_account.create_for_currency(
        :currency => nil,
      )
      expect(result).not_to be_success

      errors = result.errors.for(:merchant).on(:currency)
      expect(errors[0].code).to eq(Braintree::ErrorCodes::Merchant::CurrencyIsRequired)

      result = gateway.merchant_account.create_for_currency({})
      expect(result).not_to be_success

      errors = result.errors.for(:merchant).on(:currency)
      expect(errors[0].code).to eq(Braintree::ErrorCodes::Merchant::CurrencyIsRequired)
    end

    it "returns error if a currency is not supported" do
      result = SpecHelper::create_merchant
      expect(result).to be_success

      gateway = Braintree::Gateway.new(
        :access_token => result.credentials.access_token,
        :logger => Logger.new("/dev/null"),
      )

      result = gateway.merchant_account.create_for_currency(
        :currency => "FAKE_CURRENCY",
      )
      expect(result).not_to be_success

      errors = result.errors.for(:merchant).on(:currency)
      expect(errors[0].code).to eq(Braintree::ErrorCodes::Merchant::CurrencyIsInvalid)
    end

    it "returns error if id is passed and already taken" do
      result = SpecHelper::create_merchant
      expect(result).to be_success

      gateway = Braintree::Gateway.new(
        :access_token => result.credentials.access_token,
        :logger => Logger.new("/dev/null"),
      )

      merchant = result.merchant
      result = gateway.merchant_account.create_for_currency(
        :currency => "USD",
        :id => merchant.merchant_accounts.first.id,
      )
      expect(result).not_to be_success

      errors = result.errors.for(:merchant).on(:id)
      expect(errors[0].code).to eq(Braintree::ErrorCodes::Merchant::MerchantAccountExistsForId)
    end
  end

  describe "find" do
    it "retrieves the currency iso code for an existing master merchant account" do
      merchant_account = Braintree::MerchantAccount.find("sandbox_master_merchant_account")

      expect(merchant_account.currency_iso_code).to eq("USD")
    end

    it "raises a NotFoundError exception if merchant account cannot be found" do
      expect do
        Braintree::MerchantAccount.find("non-existant")
      end.to raise_error(Braintree::NotFoundError, "Merchant account with id non-existant not found")
    end
  end
end
