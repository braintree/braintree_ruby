require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/spec_helper")

describe Braintree::AuthorizationFingerprint do

  describe "self.generate" do
    it "generates a fingerprint that the gateway accepts" do
      config = Braintree::Configuration.instantiate
      fingerprint = Braintree::AuthorizationFingerprint.generate({
        :merchant_id => config.merchant_id,
        :public_key => config.public_key,
        :created_at => Time.now
      })
      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => fingerprint,
        :session_identifier => "fake_identifier",
        :session_identifier_type => "testing",
      )

      response = http.get_cards

      response.code.should == "200"
    end
  end
end
