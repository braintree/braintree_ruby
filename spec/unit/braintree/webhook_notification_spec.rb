require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::WebhookNotification do
  describe "self.sample_notification" do
    it "builds a sample notification and signature given an identifier and kind" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id"
      )

      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

      notification.kind.should == Braintree::WebhookNotification::Kind::SubscriptionWentPastDue
      notification.subscription.id.should == "my_id"
      notification.timestamp.should be_within(10).of(Time.now.utc)
    end

    it "builds a sample notification for a partner merchant connected webhook" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::PartnerMerchantConnected,
        "my_id"
      )

      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

      notification.kind.should == Braintree::WebhookNotification::Kind::PartnerMerchantConnected
      notification.partner_merchant.merchant_public_id.should == "public_id"
      notification.partner_merchant.public_key.should == "public_key"
      notification.partner_merchant.private_key.should == "private_key"
      notification.partner_merchant.partner_merchant_id.should == "abc123"
      notification.partner_merchant.client_side_encryption_key.should == "cse_key"
      notification.timestamp.should be_within(10).of(Time.now.utc)
    end

    it "builds a sample notification for a partner merchant disconnected webhook" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::PartnerMerchantDisconnected,
        "my_id"
      )

      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

      notification.kind.should == Braintree::WebhookNotification::Kind::PartnerMerchantDisconnected
      notification.partner_merchant.partner_merchant_id.should == "abc123"
      notification.timestamp.should be_within(10).of(Time.now.utc)
    end

    it "builds a sample notification for a partner merchant declined webhook" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::PartnerMerchantDeclined,
        "my_id"
      )

      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

      notification.kind.should == Braintree::WebhookNotification::Kind::PartnerMerchantDeclined
      notification.partner_merchant.partner_merchant_id.should == "abc123"
      notification.timestamp.should be_within(10).of(Time.now.utc)
    end

    context "disputes" do
      it "builds a sample notification for a dispute opened webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::DisputeOpened,
          "my_id"
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        notification.kind.should == Braintree::WebhookNotification::Kind::DisputeOpened

        dispute = notification.dispute
        dispute.status.should == Braintree::Dispute::Status::Open
        dispute.id.should == "my_id"
        dispute.kind.should == Braintree::Dispute::Kind::Chargeback
        dispute.date_opened.should == Date.new(2014,03,21)
      end

      it "builds a sample notification for a dispute lost webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::DisputeLost,
          "my_id"
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        notification.kind.should == Braintree::WebhookNotification::Kind::DisputeLost

        dispute = notification.dispute
        dispute.status.should == Braintree::Dispute::Status::Lost
        dispute.id.should == "my_id"
        dispute.kind.should == Braintree::Dispute::Kind::Chargeback
        dispute.date_opened.should == Date.new(2014,03,21)
      end

      it "builds a sample notification for a dispute won webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::DisputeWon,
          "my_id"
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        notification.kind.should == Braintree::WebhookNotification::Kind::DisputeWon

        dispute = notification.dispute
        dispute.status.should == Braintree::Dispute::Status::Won
        dispute.id.should == "my_id"
        dispute.kind.should == Braintree::Dispute::Kind::Chargeback
        dispute.date_opened.should == Date.new(2014,03,21)
        dispute.date_won.should == Date.new(2014,03,22)
      end
    end

    context "disbursement" do
      it "builds a sample notification for a transaction disbursed webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::TransactionDisbursed,
          "my_id"
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        notification.kind.should == Braintree::WebhookNotification::Kind::TransactionDisbursed
        notification.transaction.id.should == "my_id"
        notification.transaction.amount.should == 1_00
        notification.transaction.disbursement_details.disbursement_date.should == "2013-07-09"
      end

      it "builds a sample notification for a disbursement_exception webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::DisbursementException,
          "my_id"
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        notification.kind.should == Braintree::WebhookNotification::Kind::DisbursementException
        notification.disbursement.id.should == "my_id"
        notification.disbursement.transaction_ids.should == %W{ afv56j kj8hjk }
        notification.disbursement.retry.should be(false)
        notification.disbursement.success.should be(false)
        notification.disbursement.exception_message.should == "bank_rejected"
        notification.disbursement.disbursement_date.should == Date.parse("2014-02-10")
        notification.disbursement.follow_up_action.should == "update_funding_information"
        notification.disbursement.merchant_account.id.should == "merchant_account_token"
      end

      it "builds a sample notification for a disbursement webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::Disbursement,
          "my_id"
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        notification.kind.should == Braintree::WebhookNotification::Kind::Disbursement
        notification.disbursement.id.should == "my_id"
        notification.disbursement.transaction_ids.should == %W{ afv56j kj8hjk }
        notification.disbursement.retry.should be(false)
        notification.disbursement.success.should be(true)
        notification.disbursement.exception_message.should be_nil
        notification.disbursement.disbursement_date.should == Date.parse("2014-02-10")
        notification.disbursement.follow_up_action.should be_nil
        notification.disbursement.merchant_account.id.should == "merchant_account_token"
      end
    end

    context "us bank account transactions" do
      it "builds a sample notification for a settlement webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::TransactionSettled,
          "my_id"
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        notification.kind.should == Braintree::WebhookNotification::Kind::TransactionSettled

        notification.transaction.status.should == "settled"
        notification.transaction.us_bank_account_details.account_type.should == "checking"
        notification.transaction.us_bank_account_details.account_holder_name.should == "Dan Schulman"
        notification.transaction.us_bank_account_details.routing_number.should == "123456789"
        notification.transaction.us_bank_account_details.last_4.should == "1234"
      end

      it "builds a sample notification for a settlement declined webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::TransactionSettlementDeclined,
          "my_id"
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        notification.kind.should == Braintree::WebhookNotification::Kind::TransactionSettlementDeclined

        notification.transaction.status.should == "settlement_declined"
        notification.transaction.us_bank_account_details.account_type.should == "checking"
        notification.transaction.us_bank_account_details.account_holder_name.should == "Dan Schulman"
        notification.transaction.us_bank_account_details.routing_number.should == "123456789"
        notification.transaction.us_bank_account_details.last_4.should == "1234"
      end
    end

    context "ideal payments" do
      it "builds a sample notification for a ideal_payment_complete complete webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::IdealPaymentComplete,
          "my_id"
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])
        notification.kind.should == Braintree::WebhookNotification::Kind::IdealPaymentComplete
        ideal_payment = notification.ideal_payment

        ideal_payment.id.should == "my_id"
        ideal_payment.status.should == "COMPLETE"
        ideal_payment.order_id.should == "ORDERABC"
        ideal_payment.amount.should == "10.00"
        ideal_payment.approval_url.should == "https://example.com"
        ideal_payment.ideal_transaction_id.should == "1234567890"
        ideal_payment.iban_bank_account.description.should == "DESCRIPTION ABC"
        ideal_payment.iban_bank_account.bic.should == "XXXXNLXX"
        ideal_payment.iban_bank_account.iban_country.should == "11"
        ideal_payment.iban_bank_account.iban_account_number_last_4.should == "0000"
        ideal_payment.iban_bank_account.masked_iban.should == "NL************0000"
        ideal_payment.iban_bank_account.account_holder_name.should == "Account Holder"
      end

      it "builds a sample notification for a ideal_payment_failed webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::IdealPaymentFailed,
          "my_id"
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])
        notification.kind.should == Braintree::WebhookNotification::Kind::IdealPaymentFailed
        ideal_payment = notification.ideal_payment

        ideal_payment.id.should == "my_id"
        ideal_payment.status.should == "FAILED"
        ideal_payment.order_id.should == "ORDERABC"
        ideal_payment.amount.should == "10.00"
        ideal_payment.approval_url.should == "https://example.com"
        ideal_payment.ideal_transaction_id.should == "1234567890"
      end
    end

    context "merchant account" do
      it "builds a sample notification for a merchant account approved webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::SubMerchantAccountApproved,
          "my_id"
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        notification.kind.should == Braintree::WebhookNotification::Kind::SubMerchantAccountApproved
        notification.merchant_account.id.should == "my_id"
        notification.merchant_account.status.should == Braintree::MerchantAccount::Status::Active
        notification.merchant_account.master_merchant_account.id.should == "master_ma_for_my_id"
        notification.merchant_account.master_merchant_account.status.should == Braintree::MerchantAccount::Status::Active
      end

      it "builds a sample notification for a merchant account declined webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::SubMerchantAccountDeclined,
          "my_id"
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        notification.kind.should == Braintree::WebhookNotification::Kind::SubMerchantAccountDeclined
        notification.merchant_account.id.should == "my_id"
        notification.merchant_account.status.should == Braintree::MerchantAccount::Status::Suspended
        notification.merchant_account.master_merchant_account.id.should == "master_ma_for_my_id"
        notification.merchant_account.master_merchant_account.status.should == Braintree::MerchantAccount::Status::Suspended
        notification.message.should == "Credit score is too low"
        notification.errors.for(:merchant_account).on(:base).first.code.should == Braintree::ErrorCodes::MerchantAccount::DeclinedOFAC
      end
    end

    context "subscription" do
      it "builds a sample notification for a subscription charged successfully webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::SubscriptionChargedSuccessfully,
          "my_id"
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        notification.kind.should == Braintree::WebhookNotification::Kind::SubscriptionChargedSuccessfully
        notification.subscription.id.should == "my_id"
        notification.subscription.transactions.size.should == 1
        notification.subscription.transactions.first.status.should == Braintree::Transaction::Status::SubmittedForSettlement
        notification.subscription.transactions.first.amount.should == BigDecimal("49.99")
      end
    end

    it "includes a valid signature" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id"
      )
      expected_signature = Braintree::Digest.hexdigest(Braintree::Configuration.private_key, sample_notification[:bt_payload])

      sample_notification[:bt_signature].should == "#{Braintree::Configuration.public_key}|#{expected_signature}"
    end
  end

  context "account_updater_daily_report" do
    it "builds a sample notification for an account_updater_daily_report webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::AccountUpdaterDailyReport,
          "my_id"
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        notification.kind.should == Braintree::WebhookNotification::Kind::AccountUpdaterDailyReport
        notification.account_updater_daily_report.report_url.should == "link-to-csv-report"
        notification.account_updater_daily_report.report_date.should == Date.parse("2016-01-14")
    end
  end

  describe "parse" do
    it "raises InvalidSignature error when the signature is completely invalid" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id"
      )

      expect do
        Braintree::WebhookNotification.parse("not a valid signature", sample_notification[:bt_payload])
      end.to raise_error(Braintree::InvalidSignature)
    end

    it "raises InvalidSignature error with a message when the public key is not found" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
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
        gateway.webhook_notification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])
      end.to raise_error(Braintree::InvalidSignature, /no matching public key/)
    end

    it "raises InvalidSignature error if the payload has been changed" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id"
      )

      expect do
        Braintree::WebhookNotification.parse(sample_notification[:bt_signature], "badstuff" + sample_notification[:bt_payload])
      end.to raise_error(Braintree::InvalidSignature, /signature does not match payload - one has been modified/)
    end

    it "raises InvalidSignature error with a message complaining about invalid characters" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id"
      )

      expect do
        Braintree::WebhookNotification.parse(sample_notification[:bt_signature], "^& bad ,* chars @!" + sample_notification[:bt_payload])
      end.to raise_error(Braintree::InvalidSignature, /payload contains illegal characters/)
    end

    it "allows all valid characters" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id"
      )

      sample_notification[:bt_payload] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+=/\n"

      begin
        Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])
      rescue Braintree::InvalidSignature => e
        exception = e
      end

      exception.message.should_not match(/payload contains illegal characters/)
    end

    it "retries a payload with a newline" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id"
      )

      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload].rstrip)

      notification.kind.should == Braintree::WebhookNotification::Kind::SubscriptionWentPastDue
      notification.subscription.id.should == "my_id"
      notification.timestamp.should be_within(10).of(Time.now.utc)
    end
  end

  describe "check?" do
    it "returns true for check webhook kinds" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::Check,
        nil
      )

      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload].rstrip)

      notification.check?.should == true
    end

    it "returns false for non-check webhook kinds" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        nil
      )

      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload].rstrip)

      notification.check?.should == false
    end
  end

  describe "self.verify" do
    it "creates a verification string" do
      response = Braintree::WebhookNotification.verify("20f9f8ed05f77439fe955c977e4c8a53")
      response.should == "integration_public_key|d9b899556c966b3f06945ec21311865d35df3ce4"
    end

    it "raises InvalidChallenge error with a message complaining about invalid characters" do
      challenge = "bad challenge"

      expect do
        Braintree::WebhookNotification.verify(challenge)
      end.to raise_error(Braintree::InvalidChallenge, /challenge contains non-hex characters/)
    end
  end
end
