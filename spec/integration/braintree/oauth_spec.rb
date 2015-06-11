require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe "OAuth" do
  before(:each) do
    @gateway = Braintree::Gateway.new(
      :client_id => "client_id$development$integration_client_id",
      :client_secret => "client_secret$development$integration_client_secret",
      :logger => Logger.new("/dev/null"),
    )
  end

  describe "self.create_token_from_code" do
    it "creates an access token given a grant code" do
      code = Braintree::OAuthTestHelper.create_grant(@gateway, {
        :merchant_public_id => "integration_merchant_id",
        :scope => "read_write",
      })

      result = @gateway.oauth.create_token_from_code(
        :code => code,
        :scope => "read_write",
      )

      result.should be_success
      credentials = result.credentials
      credentials.access_token.should_not be_nil
      credentials.refresh_token.should_not be_nil
      credentials.expires_at.should_not be_nil
      credentials.token_type.should == "bearer"
    end

    it "returns validation errors for bad params" do
      result = @gateway.oauth.create_token_from_code(
        :code => "bad_code",
        :scope => "read_write",
      )

      result.should_not be_success
      errors = result.errors.for(:credentials).on(:code)[0].code.should == Braintree::ErrorCodes::OAuth::InvalidGrant
      result.message.should =~ /Invalid grant: code not found/
    end
  end

  describe "self.create_token_from_refresh_token" do
    it "creates an access token given a refresh token" do
      code = Braintree::OAuthTestHelper.create_grant(@gateway, {
        :merchant_public_id => "integration_merchant_id",
        :scope => "read_write",
      })
      refresh_token = @gateway.oauth.create_token_from_code(
        :code => code,
        :scope => "read_write",
      ).credentials.refresh_token

      result = @gateway.oauth.create_token_from_refresh_token(
        :refresh_token => refresh_token,
        :scope => "read_write",
      )

      result.should be_success
      credentials = result.credentials
      credentials.access_token.should_not be_nil
      credentials.refresh_token.should_not be_nil
      credentials.expires_at.should_not be_nil
      credentials.token_type.should == "bearer"
    end
  end
end
