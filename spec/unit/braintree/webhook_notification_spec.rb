require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::WebhookNotification do
  describe "self.sample_notification" do
    it "supports id-only invocation" do
      signature, payload = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id"
      )

      notification = Braintree::WebhookNotification.parse(signature, payload)
      notification.subscription.id.should == "my_id"
    end

    it "builds a sample notification and signature given an identifier and kind" do
      signature, payload = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        :id => "my_id"
      )

      notification = Braintree::WebhookNotification.parse(signature, payload)

      notification.kind.should == Braintree::WebhookNotification::Kind::SubscriptionWentPastDue
      notification.subscription.id.should == "my_id"
      notification.timestamp.should be_close(Time.now.utc, 10)
    end

    it "builds a sample notification for a partner connection created webhook" do
      signature, payload = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::PartnerConnectionCreated,
        :merchant_public_id => "public_id",
        :public_key => "public_key",
        :private_key => "private_key",
        :partnership_user_id => "abc123"
      )

      notification = Braintree::WebhookNotification.parse(signature, payload)

      notification.kind.should == Braintree::WebhookNotification::Kind::PartnerConnectionCreated
      notification.partner_connection.merchant_public_id.should == "public_id"
      notification.partner_connection.public_key.should == "public_key"
      notification.partner_connection.private_key.should == "private_key"
      notification.partner_connection.partnership_user_id.should == "abc123"
      notification.timestamp.should be_close(Time.now.utc, 10)
    end

    it "builds a sample notification for transactions disbursed webhook" do
      transaction_ids = %w(a b c d)
      signature, payload = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::TransactionsDisbursed,
        :transaction_ids => transaction_ids
      )

      notification = Braintree::WebhookNotification.parse(signature, payload)

      notification.kind.should == Braintree::WebhookNotification::Kind::TransactionsDisbursed
      notification.transaction_ids.should == transaction_ids
    end

    context "merchant account" do
      it "builds a sample notification for a merchant account approved webhook" do
        signature, payload = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::SubMerchantAccountApproved,
          :id => "sub_merchant_account_id",
          :status => Braintree::MerchantAccount::Status::Active,
          :master_merchant_account => {
            :id => "master_merchant_account_id",
            :status => Braintree::MerchantAccount::Status::Active
          }
        )

        notification = Braintree::WebhookNotification.parse(signature, payload)

        notification.kind.should == Braintree::WebhookNotification::Kind::SubMerchantAccountApproved
        notification.merchant_account.id.should == "sub_merchant_account_id"
        notification.merchant_account.status.should == Braintree::MerchantAccount::Status::Active
        notification.merchant_account.master_merchant_account.id.should == "master_merchant_account_id"
        notification.merchant_account.master_merchant_account.status.should == Braintree::MerchantAccount::Status::Active
      end

      it "builds a sample notification for a merchant account declined webhook" do
        signature, payload = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::SubMerchantAccountDeclined,
          :message => "Applicant declined due to OFAC.",
          :merchant_account => {
            :id => "sub_merchant_account_id",
            :status => Braintree::MerchantAccount::Status::Suspended,
            :master_merchant_account => {
              :id => "master_merchant_account_id",
              :status => Braintree::MerchantAccount::Status::Active
            }
          },
          :errors => [{
            :attribute => :base,
            :code => "82621",
            :message => "Applicant declined due to OFAC."
          }]
        )

        notification = Braintree::WebhookNotification.parse(signature, payload)

        notification.kind.should == Braintree::WebhookNotification::Kind::SubMerchantAccountDeclined
        notification.errors.merchant_account.id.should == "sub_merchant_account_id"
        notification.errors.merchant_account.status.should == Braintree::MerchantAccount::Status::Suspended
        notification.errors.merchant_account.master_merchant_account.id.should == "master_merchant_account_id"
        notification.errors.merchant_account.master_merchant_account.status.should == Braintree::MerchantAccount::Status::Active
        notification.errors.message.should == "Applicant declined due to OFAC."
        notification.errors.errors.for(:merchant_account).on(:base).first.code.should == Braintree::ErrorCodes::MerchantAccount::ApplicantDetails::DeclinedOFAC
      end
    end

    it "includes a valid signature" do
      signature, payload = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        :id => "my_id"
      )
      expected_signature = Braintree::Digest.hexdigest(Braintree::Configuration.private_key, payload)

      signature.should == "#{Braintree::Configuration.public_key}|#{expected_signature}"
    end
  end

  describe "parse" do
    it "raises InvalidSignature error the signature is completely invalid" do
      signature, payload = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        :id => "my_id"
      )

      expect do
        notification = Braintree::WebhookNotification.parse("not a valid signature", payload)
      end.to raise_error(Braintree::InvalidSignature)
    end

    it "raises InvalidSignature error the payload has been changed" do
      signature, payload = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        :id => "my_id"
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
