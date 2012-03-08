require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Webhook do
  describe "self.sample_notification" do
    it "builds a sample notification and signature given an identifier and kind" do
      signature, payload = Braintree::Webhook.sample_notification(
        Braintree::Webhook::Kind::SubscriptionPastDue,
        "my_id"
      )

      notification = Braintree::Webhook.parse(signature, payload)

      notification.kind.should == Braintree::Webhook::Kind::SubscriptionPastDue
      notification.subscription.id.should == "my_id"
    end

    it "includes a valid signature" do
      signature, payload = Braintree::Webhook.sample_notification(Braintree::Webhook::Kind::SubscriptionPastDue, "my_id")
      expected_signature = Braintree::Digest.hexdigest(Braintree::Configuration.private_key, payload)

      signature.should == "#{Braintree::Configuration.public_key}|#{expected_signature}"
    end
  end

  describe "parse" do
    it "raises InvalidSignature error the signature is completely invalid" do
      signature, payload = Braintree::Webhook.sample_notification(
        Braintree::Webhook::Kind::SubscriptionPastDue,
        "my_id"
      )

      expect do
        notification = Braintree::Webhook.parse("not a valid signature", payload)
      end.to raise_error(Braintree::InvalidSignature)
    end

    it "raises InvalidSignature error the payload has been changed" do
      signature, payload = Braintree::Webhook.sample_notification(
        Braintree::Webhook::Kind::SubscriptionPastDue,
        "my_id"
      )

      expect do
        notification = Braintree::Webhook.parse(signature, payload + "bad stuff")
      end.to raise_error(Braintree::InvalidSignature)
    end
  end

  describe "self.verify" do
    it "creates a verification string" do
      response = Braintree::Webhook.verify("verification_token")
      response.should == "integration_public_key|c9f15b74b0d98635cd182c51e2703cffa83388c3"
    end
  end
end
