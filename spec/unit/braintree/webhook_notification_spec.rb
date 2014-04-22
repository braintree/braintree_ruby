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

    it "builds a sample notification for a partner merchant connected webhook" do
      signature, payload = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::PartnerMerchantConnected,
        "my_id"
      )

      notification = Braintree::WebhookNotification.parse(signature, payload)

      notification.kind.should == Braintree::WebhookNotification::Kind::PartnerMerchantConnected
      notification.partner_merchant.merchant_public_id.should == "public_id"
      notification.partner_merchant.public_key.should == "public_key"
      notification.partner_merchant.private_key.should == "private_key"
      notification.partner_merchant.partner_merchant_id.should == "abc123"
      notification.partner_merchant.client_side_encryption_key.should == "cse_key"
      notification.timestamp.should be_close(Time.now.utc, 10)
    end

    it "builds a sample notification for a partner merchant disconnected webhook" do
      signature, payload = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::PartnerMerchantDisconnected,
        "my_id"
      )

      notification = Braintree::WebhookNotification.parse(signature, payload)

      notification.kind.should == Braintree::WebhookNotification::Kind::PartnerMerchantDisconnected
      notification.partner_merchant.partner_merchant_id.should == "abc123"
      notification.timestamp.should be_close(Time.now.utc, 10)
    end

    it "builds a sample notification for a partner merchant declined webhook" do
      signature, payload = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::PartnerMerchantDeclined,
        "my_id"
      )

      notification = Braintree::WebhookNotification.parse(signature, payload)

      notification.kind.should == Braintree::WebhookNotification::Kind::PartnerMerchantDeclined
      notification.partner_merchant.partner_merchant_id.should == "abc123"
      notification.timestamp.should be_close(Time.now.utc, 10)
    end

    context "disbursement" do
      it "builds a sample notification for a transaction disbursed webhook" do
        signature, payload = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::TransactionDisbursed,
          "my_id"
        )

        notification = Braintree::WebhookNotification.parse(signature, payload)

        notification.kind.should == Braintree::WebhookNotification::Kind::TransactionDisbursed
        notification.transaction.id.should == "my_id"
        notification.transaction.amount.should == 1_00
        notification.transaction.disbursement_details.disbursement_date.should == "2013-07-09"
      end

      it "builds a sample notification for a disbursement_exception webhook" do
        signature, payload = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::DisbursementException,
          "my_id"
        )

        notification = Braintree::WebhookNotification.parse(signature, payload)

        notification.kind.should == Braintree::WebhookNotification::Kind::DisbursementException
        notification.disbursement.id.should == "my_id"
        notification.disbursement.transaction_ids.should == %W{ afv56j kj8hjk }
        notification.disbursement.retry.should be_false
        notification.disbursement.success.should be_false
        notification.disbursement.exception_message.should == "bank_rejected"
        notification.disbursement.disbursement_date.should == Date.parse("2014-02-10")
        notification.disbursement.follow_up_action.should == "update_funding_information"
        notification.disbursement.merchant_account.id.should == "merchant_account_token"
      end

      it "builds a sample notification for a disbursement webhook" do
        signature, payload = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::Disbursement,
          "my_id"
        )

        notification = Braintree::WebhookNotification.parse(signature, payload)

        notification.kind.should == Braintree::WebhookNotification::Kind::Disbursement
        notification.disbursement.id.should == "my_id"
        notification.disbursement.transaction_ids.should == %W{ afv56j kj8hjk }
        notification.disbursement.retry.should be_false
        notification.disbursement.success.should be_true
        notification.disbursement.exception_message.should be_nil
        notification.disbursement.disbursement_date.should == Date.parse("2014-02-10")
        notification.disbursement.follow_up_action.should be_nil
        notification.disbursement.merchant_account.id.should == "merchant_account_token"
      end
    end

    context "merchant account" do
      it "builds a sample notification for a merchant account approved webhook" do
        signature, payload = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::SubMerchantAccountApproved,
          "my_id"
        )

        notification = Braintree::WebhookNotification.parse(signature, payload)

        notification.kind.should == Braintree::WebhookNotification::Kind::SubMerchantAccountApproved
        notification.merchant_account.id.should == "my_id"
        notification.merchant_account.status.should == Braintree::MerchantAccount::Status::Active
        notification.merchant_account.master_merchant_account.id.should == "master_ma_for_my_id"
        notification.merchant_account.master_merchant_account.status.should == Braintree::MerchantAccount::Status::Active
      end

      it "builds a sample notification for a merchant account declined webhook" do
        signature, payload = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::SubMerchantAccountDeclined,
          "my_id"
        )

        notification = Braintree::WebhookNotification.parse(signature, payload)

        notification.kind.should == Braintree::WebhookNotification::Kind::SubMerchantAccountDeclined
        notification.merchant_account.id.should == "my_id"
        notification.merchant_account.status.should == Braintree::MerchantAccount::Status::Suspended
        notification.merchant_account.master_merchant_account.id.should == "master_ma_for_my_id"
        notification.merchant_account.master_merchant_account.status.should == Braintree::MerchantAccount::Status::Suspended
        notification.message.should == "Credit score is too low"
        notification.errors.for(:merchant_account).on(:base).first.code.should == Braintree::ErrorCodes::MerchantAccount::DeclinedOFAC
      end
    end

    it "includes a valid signature" do
      signature, payload = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id"
      )
      expected_signature = Braintree::Digest.hexdigest(Braintree::Configuration.private_key, payload)

      signature.should == "#{Braintree::Configuration.public_key}|#{expected_signature}"
    end
  end

  describe "parse" do
    it "raises InvalidSignature error when the signature is completely invalid" do
      signature, payload = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id"
      )

      expect do
        notification = Braintree::WebhookNotification.parse("not a valid signature", payload)
      end.to raise_error(Braintree::InvalidSignature)
    end

    it "raises InvalidSignature error with a message when the public key is not found" do
      signature, payload = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id"
      )

      config = Braintree::Configuration.new(
        :merchant_id => 'merchant_id',
        :public_key => 'wrong_public_key',
        :private_key => 'wrong_private_key'
      )
      gateway = Braintree::Gateway.new(config)

      expect do
        notification = gateway.webhook_notification.parse(signature, payload)
      end.to raise_error(Braintree::InvalidSignature, /no matching public key/)
    end

    it "raises InvalidSignature error if the payload has been changed" do
      signature, payload = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id"
      )

      expect do
        notification = Braintree::WebhookNotification.parse(signature, "badstuff" + payload)
      end.to raise_error(Braintree::InvalidSignature, /signature does not match payload - one has been modified/)
    end

    it "raises InvalidSignature error with a message complaining about invalid characters" do
      signature, payload = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id"
      )

      expect do
        notification = Braintree::WebhookNotification.parse(signature, "^& bad ,* chars @!" + payload)
      end.to raise_error(Braintree::InvalidSignature, /payload contains illegal characters/)
    end

    it "allows all valid characters" do
      signature, payload = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id"
      )

      payload = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+=/\n"
      expect do
        notification = Braintree::WebhookNotification.parse(signature, payload)
      end.to_not raise_error(Braintree::InvalidSignature, /payload contains illegal characters/)
    end

    it "retries a payload with a newline" do
      signature, payload = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id"
      )

      notification = Braintree::WebhookNotification.parse(signature, payload.rstrip)

      notification.kind.should == Braintree::WebhookNotification::Kind::SubscriptionWentPastDue
      notification.subscription.id.should == "my_id"
      notification.timestamp.should be_close(Time.now.utc, 10)
    end
  end

  describe "self.verify" do
    it "creates a verification string" do
      response = Braintree::WebhookNotification.verify("verification_token")
      response.should == "integration_public_key|c9f15b74b0d98635cd182c51e2703cffa83388c3"
    end
  end
end
