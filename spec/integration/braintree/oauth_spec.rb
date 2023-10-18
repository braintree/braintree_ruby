require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe "OAuth" do
  before(:each) do
    @gateway = Braintree::Gateway.new(
      :client_id => "client_id$#{Braintree::Configuration.environment}$integration_client_id",
      :client_secret => "client_secret$#{Braintree::Configuration.environment}$integration_client_secret",
      :logger => Logger.new("/dev/null"),
    )
  end

  describe "create_token_from_code" do
    it "creates an access token given a grant code" do
      code = Braintree::OAuthTestHelper.create_grant(@gateway, {
        :merchant_public_id => "integration_merchant_id",
        :scope => "read_write"
      })

      result = @gateway.oauth.create_token_from_code(
        :code => code,
        :scope => "read_write",
      )

      expect(result).to be_success
      credentials = result.credentials
      expect(credentials.access_token).not_to be_nil
      expect(credentials.refresh_token).not_to be_nil
      expect(credentials.expires_at).not_to be_nil
      expect(credentials.token_type).to eq("bearer")
    end

    it "returns validation errors for bad params" do
      result = @gateway.oauth.create_token_from_code(
        :code => "bad_code",
        :scope => "read_write",
      )

      expect(result).not_to be_success
      errors = expect(result.errors.for(:credentials).on(:code)[0].code).to eq(Braintree::ErrorCodes::OAuth::InvalidGrant)
      expect(result.message).to match(/Invalid grant: code not found/)
    end

    it "raises with a helpful error if client_id and client_secret are not set" do
      gateway = Braintree::Gateway.new(
        :access_token => "access_token$development$integration_merchant_id$fb27c79dd",
        :logger => Logger.new("/dev/null"),
      )

      expect do
        gateway.oauth.create_token_from_code(
          :code => "some code",
          :scope => "read_write",
        )
      end.to raise_error(Braintree::ConfigurationError, /client_id and client_secret are required/);
    end
  end

  describe "create_token_from_refresh_token" do
    it "creates an access token given a refresh token" do
      code = Braintree::OAuthTestHelper.create_grant(@gateway, {
        :merchant_public_id => "integration_merchant_id",
        :scope => "read_write"
      })
      refresh_token = @gateway.oauth.create_token_from_code(
        :code => code,
        :scope => "read_write",
      ).credentials.refresh_token

      result = @gateway.oauth.create_token_from_refresh_token(
        :refresh_token => refresh_token,
        :scope => "read_write",
      )

      expect(result).to be_success
      credentials = result.credentials
      expect(credentials.access_token).not_to be_nil
      expect(credentials.refresh_token).not_to be_nil
      expect(credentials.expires_at).not_to be_nil
      expect(credentials.token_type).to eq("bearer")
    end
  end

  describe "revoke_access_token" do
    it "revokes an access token" do
      code = Braintree::OAuthTestHelper.create_grant(@gateway, {
        :merchant_public_id => "integration_merchant_id",
        :scope => "read_write"
      })
      access_token = @gateway.oauth.create_token_from_code(
        :code => code,
        :scope => "read_write",
      ).credentials.access_token

      result = @gateway.oauth.revoke_access_token(access_token)
      expect(result).to be_success

      gateway = Braintree::Gateway.new(
        :access_token => access_token,
        :logger => Logger.new("/dev/null"),
      )

      expect do
        gateway.customer.create
      end.to raise_error(Braintree::AuthenticationError)
    end
  end

  describe "connect_url" do
    it "builds a connect url" do
      url = @gateway.oauth.connect_url(
        :merchant_id => "integration_merchant_id",
        :redirect_uri => "http://bar.example.com",
        :scope => "read_write",
        :state => "baz_state",
        :landing_page => "signup",
        :login_only => false,
        :user => {
          :country => "USA",
          :email => "foo@example.com",
          :first_name => "Bob",
          :last_name => "Jones",
          :phone => "555-555-5555",
          :dob_year => "1970",
          :dob_month => "01",
          :dob_day => "01",
          :street_address => "222 W Merchandise Mart",
          :locality => "Chicago",
          :region => "IL",
          :postal_code => "60606"
        },
        :business => {
          :name => "14 Ladders",
          :registered_as => "14.0 Ladders",
          :industry => "Ladders",
          :description => "We sell the best ladders",
          :street_address => "111 N Canal",
          :locality => "Chicago",
          :region => "IL",
          :postal_code => "60606",
          :country => "USA",
          :annual_volume_amount => "1000000",
          :average_transaction_amount => "100",
          :maximum_transaction_amount => "10000",
          :ship_physical_goods => true,
          :fulfillment_completed_in => 7,
          :currency => "USD",
          :website => "http://example.com"
        },
        :payment_methods => ["credit_card", "paypal"],
      )

      uri = URI.parse(url)
      expect(uri.host).to eq(Braintree::Configuration.instantiate.server)
      expect(uri.path).to eq("/oauth/connect")

      query = CGI.parse(uri.query)
      expect(query["merchant_id"]).to eq(["integration_merchant_id"])
      expect(query["client_id"]).to eq(["client_id$#{Braintree::Configuration.environment}$integration_client_id"])
      expect(query["redirect_uri"]).to eq(["http://bar.example.com"])
      expect(query["scope"]).to eq(["read_write"])
      expect(query["state"]).to eq(["baz_state"])
      expect(query["landing_page"]).to eq(["signup"])
      expect(query["login_only"]).to eq(["false"])

      expect(query["user[country]"]).to eq(["USA"])
      expect(query["business[name]"]).to eq(["14 Ladders"])

      expect(query["user[email]"]).to eq(["foo@example.com"])
      expect(query["user[first_name]"]).to eq(["Bob"])
      expect(query["user[last_name]"]).to eq(["Jones"])
      expect(query["user[phone]"]).to eq(["555-555-5555"])
      expect(query["user[dob_year]"]).to eq(["1970"])
      expect(query["user[dob_month]"]).to eq(["01"])
      expect(query["user[dob_day]"]).to eq(["01"])
      expect(query["user[street_address]"]).to eq(["222 W Merchandise Mart"])
      expect(query["user[locality]"]).to eq(["Chicago"])
      expect(query["user[region]"]).to eq(["IL"])
      expect(query["user[postal_code]"]).to eq(["60606"])

      expect(query["business[name]"]).to eq(["14 Ladders"])
      expect(query["business[registered_as]"]).to eq(["14.0 Ladders"])
      expect(query["business[industry]"]).to eq(["Ladders"])
      expect(query["business[description]"]).to eq(["We sell the best ladders"])
      expect(query["business[street_address]"]).to eq(["111 N Canal"])
      expect(query["business[locality]"]).to eq(["Chicago"])
      expect(query["business[region]"]).to eq(["IL"])
      expect(query["business[postal_code]"]).to eq(["60606"])
      expect(query["business[country]"]).to eq(["USA"])
      expect(query["business[annual_volume_amount]"]).to eq(["1000000"])
      expect(query["business[average_transaction_amount]"]).to eq(["100"])
      expect(query["business[maximum_transaction_amount]"]).to eq(["10000"])
      expect(query["business[ship_physical_goods]"]).to eq(["true"])
      expect(query["business[fulfillment_completed_in]"]).to eq(["7"])
      expect(query["business[currency]"]).to eq(["USD"])
      expect(query["business[website]"]).to eq(["http://example.com"])
    end

    it "builds the query string with multiple payment_methods" do
      url = @gateway.oauth.connect_url(
        :merchant_id => "integration_merchant_id",
        :redirect_uri => "http://bar.example.com",
        :scope => "read_write",
        :state => "baz_state",
        :payment_methods => ["credit_card", "paypal"],
      )

      uri = URI.parse(url)
      expect(uri.host).to eq(Braintree::Configuration.instantiate.server)
      expect(uri.path).to eq("/oauth/connect")

      query = CGI.parse(CGI.unescape(uri.query))
      expect(query["payment_methods[]"].length).to eq(2)
      expect(query["payment_methods[]"]).to include("paypal")
      expect(query["payment_methods[]"]).to include("credit_card")
    end

    it "doesn't mutate the options" do
      params = {:payment_methods => ["credit_card"]}

      @gateway.oauth.connect_url(params)

      expect(params).to eq({:payment_methods => ["credit_card"]})
    end
  end
end
