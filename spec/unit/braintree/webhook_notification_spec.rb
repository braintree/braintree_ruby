require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::WebhookNotification do
  describe "self.sample_notification" do
    it "builds a sample notification and signature given an identifier and kind" do
      signature, payload = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id"
      )

      notification = Braintree::WebhookNotification.parse(signature, payload)

      notification.kind.should == Braintree::WebhookNotification::Kind::SubscriptionWentPastDue
      notification.subscription.id.should == "my_id"
      notification.timestamp.should be_close(Time.now.utc, 10)
    end

    it "includes a valid signature" do
      signature, payload = Braintree::WebhookTesting.sample_notification(Braintree::WebhookNotification::Kind::SubscriptionWentPastDue, "my_id")
      expected_signature = Braintree::Digest.hexdigest(Braintree::Configuration.private_key, payload)

      signature.should == "#{Braintree::Configuration.public_key}|#{expected_signature}"
    end
  end

  describe "parse" do
    it "raises InvalidSignature error the signature is completely invalid" do
      signature, payload = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id"
      )

      expect do
        notification = Braintree::WebhookNotification.parse("not a valid signature", payload)
      end.to raise_error(Braintree::InvalidSignature)
    end

    it "raises InvalidSignature error the payload has been changed" do
      signature, payload = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id"
      )

      expect do
        notification = Braintree::WebhookNotification.parse(signature, payload + "bad stuff")
      end.to raise_error(Braintree::InvalidSignature)
    end
  end

  describe "self.verify" do
    it "creates a verification string" do
      response = Braintree::WebhookNotification.verify("verification_token")
      response.should == "integration_public_key|c9f15b74b0d98635cd182c51e2703cffa83388c3"
    end
  end
end
