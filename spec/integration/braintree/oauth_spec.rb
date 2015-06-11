require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe "OAuth" do
  before(:each) do
    @gateway = Braintree::Gateway.new(
      :client_id => "client_id$development$integration_client_id",
      :client_secret => "client_secret$development$integration_client_secret",
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
  end
end
