require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Webhook do
  describe "self.verify" do
    it "creates a verification string" do
      response = Braintree::Webhook.verify("verification_token")
      response.should == "integration_public_key|c9f15b74b0d98635cd182c51e2703cffa83388c3"
    end
  end
end
