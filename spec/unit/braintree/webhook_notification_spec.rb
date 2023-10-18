require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::WebhookNotification do
  describe "self.sample_notification" do
    it "builds a sample notification and signature given an identifier and kind" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id",
      )

      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

      expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::SubscriptionWentPastDue)
      expect(notification.subscription.id).to eq("my_id")
      expect(notification.timestamp).to be_within(10).of(Time.now.utc)
    end

    it "builds a sample notification for a partner merchant connected webhook" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::PartnerMerchantConnected,
        "my_id",
      )

      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

      expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::PartnerMerchantConnected)
      expect(notification.partner_merchant.merchant_public_id).to eq("public_id")
      expect(notification.partner_merchant.public_key).to eq("public_key")
      expect(notification.partner_merchant.private_key).to eq("private_key")
      expect(notification.partner_merchant.partner_merchant_id).to eq("abc123")
      expect(notification.partner_merchant.client_side_encryption_key).to eq("cse_key")
      expect(notification.timestamp).to be_within(10).of(Time.now.utc)
    end

    it "builds a sample notification for a partner merchant disconnected webhook" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::PartnerMerchantDisconnected,
        "my_id",
      )

      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

      expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::PartnerMerchantDisconnected)
      expect(notification.partner_merchant.partner_merchant_id).to eq("abc123")
      expect(notification.timestamp).to be_within(10).of(Time.now.utc)
    end

    it "builds a sample notification for a partner merchant declined webhook" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::PartnerMerchantDeclined,
        "my_id",
      )

      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

      expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::PartnerMerchantDeclined)
      expect(notification.partner_merchant.partner_merchant_id).to eq("abc123")
      expect(notification.timestamp).to be_within(10).of(Time.now.utc)
    end

    it "builds a sample notification with a source merchant ID" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id",
        "my_source_merchant_id",
      )

      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

      expect(notification.source_merchant_id).to eq("my_source_merchant_id")
    end

    it "doesn't include source merchant IDs if not supplied" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::PartnerMerchantDeclined,
        "my_id",
      )

      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

      expect(notification.source_merchant_id).to be_nil
    end

    context "auth" do
      it "builds a sample notification for a status transitioned webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::ConnectedMerchantStatusTransitioned,
          "my_id",
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::ConnectedMerchantStatusTransitioned)

        status_transitioned = notification.connected_merchant_status_transitioned
        expect(status_transitioned.merchant_public_id).to eq("my_id")
        expect(status_transitioned.merchant_id).to eq("my_id")
        expect(status_transitioned.oauth_application_client_id).to eq("oauth_application_client_id")
        expect(status_transitioned.status).to eq("new_status")
      end

      it "builds a sample notification for a paypal status changed webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::ConnectedMerchantPayPalStatusChanged,
          "my_id",
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::ConnectedMerchantPayPalStatusChanged)

        paypal_status_changed = notification.connected_merchant_paypal_status_changed
        expect(paypal_status_changed.merchant_public_id).to eq("my_id")
        expect(paypal_status_changed.merchant_id).to eq("my_id")
        expect(paypal_status_changed.oauth_application_client_id).to eq("oauth_application_client_id")
        expect(paypal_status_changed.action).to eq("link")
      end

      it "builds a sample notification for OAuth application revocation" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::OAuthAccessRevoked,
          "my_id",
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::OAuthAccessRevoked)
        expect(notification.oauth_access_revocation.merchant_id).to eq("my_id")
        expect(notification.oauth_access_revocation.oauth_application_client_id).to eq("oauth_application_client_id")
        expect(notification.timestamp).to be_within(10).of(Time.now.utc)
      end

    end

    context "disputes" do
      let(:dispute_id) { "my_id" }

      shared_examples "dispute webhooks" do
        it "builds a sample notification for a dispute opened webhook" do
          sample_notification = Braintree::WebhookTesting.sample_notification(
            Braintree::WebhookNotification::Kind::DisputeOpened,
            dispute_id,
          )

          notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

          expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::DisputeOpened)

          dispute = notification.dispute
          expect(dispute.status).to eq(Braintree::Dispute::Status::Open)
          expect(dispute.id).to eq(dispute_id)
          expect(dispute.kind).to eq(Braintree::Dispute::Kind::Chargeback)
        end

        it "builds a sample notification for a dispute lost webhook" do
          sample_notification = Braintree::WebhookTesting.sample_notification(
            Braintree::WebhookNotification::Kind::DisputeLost,
            dispute_id,
          )

          notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

          expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::DisputeLost)

          dispute = notification.dispute
          expect(dispute.status).to eq(Braintree::Dispute::Status::Lost)
          expect(dispute.id).to eq(dispute_id)
          expect(dispute.kind).to eq(Braintree::Dispute::Kind::Chargeback)
        end

        it "builds a sample notification for a dispute won webhook" do
          sample_notification = Braintree::WebhookTesting.sample_notification(
            Braintree::WebhookNotification::Kind::DisputeWon,
            dispute_id,
          )

          notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

          expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::DisputeWon)

          dispute = notification.dispute
          expect(dispute.status).to eq(Braintree::Dispute::Status::Won)
          expect(dispute.id).to eq(dispute_id)
          expect(dispute.kind).to eq(Braintree::Dispute::Kind::Chargeback)
        end

        it "builds a sample notification for a dispute accepted webhook" do
          sample_notification = Braintree::WebhookTesting.sample_notification(
            Braintree::WebhookNotification::Kind::DisputeAccepted,
            dispute_id,
          )

          notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

          expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::DisputeAccepted)

          dispute = notification.dispute
          expect(dispute.status).to eq(Braintree::Dispute::Status::Accepted)
          expect(dispute.id).to eq(dispute_id)
          expect(dispute.kind).to eq(Braintree::Dispute::Kind::Chargeback)
        end

        it "builds a sample notification for a dispute auto_accepted webhook" do
          sample_notification = Braintree::WebhookTesting.sample_notification(
            Braintree::WebhookNotification::Kind::DisputeAutoAccepted,
            dispute_id,
          )

          notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

          expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::DisputeAutoAccepted)

          dispute = notification.dispute
          expect(dispute.status).to eq(Braintree::Dispute::Status::AutoAccepted)
          expect(dispute.id).to eq(dispute_id)
          expect(dispute.kind).to eq(Braintree::Dispute::Kind::Chargeback)
        end

        it "builds a sample notification for a dispute disputed webhook" do
          sample_notification = Braintree::WebhookTesting.sample_notification(
            Braintree::WebhookNotification::Kind::DisputeDisputed,
            dispute_id,
          )

          notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

          expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::DisputeDisputed)

          dispute = notification.dispute
          expect(dispute.status).to eq(Braintree::Dispute::Status::Disputed)
          expect(dispute.id).to eq(dispute_id)
          expect(dispute.kind).to eq(Braintree::Dispute::Kind::Chargeback)
        end

        it "builds a sample notification for a dispute expired webhook" do
          sample_notification = Braintree::WebhookTesting.sample_notification(
            Braintree::WebhookNotification::Kind::DisputeExpired,
            dispute_id,
          )

          notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

          expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::DisputeExpired)

          dispute = notification.dispute
          expect(dispute.status).to eq(Braintree::Dispute::Status::Expired)
          expect(dispute.id).to eq(dispute_id)
          expect(dispute.kind).to eq(Braintree::Dispute::Kind::Chargeback)
        end

        it "is compatible with the previous dispute won webhook interface" do
          sample_notification = Braintree::WebhookTesting.sample_notification(
            Braintree::WebhookNotification::Kind::DisputeWon,
            dispute_id,
          )

          notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

          expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::DisputeWon)

          dispute = notification.dispute
          expect(dispute.amount).to eq(100.00)
          expect(dispute.id).to eq(dispute_id)
          expect(dispute.date_opened).to eq(Date.new(2014, 3, 21))
          expect(dispute.date_won).to eq(Date.new(2014, 3, 22))
          expect(dispute.transaction_details.amount).to eq(100.00)
          expect(dispute.transaction_details.id).to eq(dispute_id)
        end
      end

      context "older webhooks" do
        let(:dispute_id) { "legacy_dispute_id" }

        include_examples "dispute webhooks"
      end

      context "newer webhooks" do
        include_examples "dispute webhooks"
      end
    end

    context "disbursement" do
      it "builds a sample notification for a transaction disbursed webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::TransactionDisbursed,
          "my_id",
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::TransactionDisbursed)
        expect(notification.transaction.id).to eq("my_id")
        expect(notification.transaction.amount).to eq(1_00)
        expect(notification.transaction.disbursement_details.disbursement_date).to eq(Date.parse("2013-07-09"))
      end

      it "builds a sample notification for a disbursement_exception webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::DisbursementException,
          "my_id",
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::DisbursementException)
        expect(notification.disbursement.id).to eq("my_id")
        expect(notification.disbursement.transaction_ids).to eq(%W{ afv56j kj8hjk })
        expect(notification.disbursement.retry).to be(false)
        expect(notification.disbursement.success).to be(false)
        expect(notification.disbursement.exception_message).to eq("bank_rejected")
        expect(notification.disbursement.disbursement_date).to eq(Date.parse("2014-02-10"))
        expect(notification.disbursement.follow_up_action).to eq("update_funding_information")
        expect(notification.disbursement.merchant_account.id).to eq("merchant_account_token")
      end

      it "builds a sample notification for a disbursement webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::Disbursement,
          "my_id",
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::Disbursement)
        expect(notification.disbursement.id).to eq("my_id")
        expect(notification.disbursement.transaction_ids).to eq(%W{ afv56j kj8hjk })
        expect(notification.disbursement.retry).to be(false)
        expect(notification.disbursement.success).to be(true)
        expect(notification.disbursement.exception_message).to be_nil
        expect(notification.disbursement.disbursement_date).to eq(Date.parse("2014-02-10"))
        expect(notification.disbursement.follow_up_action).to be_nil
        expect(notification.disbursement.merchant_account.id).to eq("merchant_account_token")
      end
    end

    context "transaction review" do
      it " builds a sample notification for a transaction reviewed webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::TransactionReviewed,
          "my_id",
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::TransactionReviewed)
        expect(notification.transaction_review.transaction_id).to eq("my_id")
        expect(notification.transaction_review.decision).to eq("decision")
        expect(notification.transaction_review.reviewer_email).to eq("hey@girl.com")
        expect(notification.transaction_review.reviewer_note).to eq("i reviewed this")
        expect(notification.transaction_review.reviewed_time).to_not be_nil
      end
    end

    context "us bank account transactions" do
      it "builds a sample notification for a settlement webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::TransactionSettled,
          "my_id",
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::TransactionSettled)

        expect(notification.transaction.status).to eq("settled")
        expect(notification.transaction.us_bank_account_details.account_type).to eq("checking")
        expect(notification.transaction.us_bank_account_details.account_holder_name).to eq("Dan Schulman")
        expect(notification.transaction.us_bank_account_details.routing_number).to eq("123456789")
        expect(notification.transaction.us_bank_account_details.last_4).to eq("1234")
      end

      it "builds a sample notification for a settlement declined webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::TransactionSettlementDeclined,
          "my_id",
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::TransactionSettlementDeclined)

        expect(notification.transaction.status).to eq("settlement_declined")
        expect(notification.transaction.us_bank_account_details.account_type).to eq("checking")
        expect(notification.transaction.us_bank_account_details.account_holder_name).to eq("Dan Schulman")
        expect(notification.transaction.us_bank_account_details.routing_number).to eq("123456789")
        expect(notification.transaction.us_bank_account_details.last_4).to eq("1234")
      end
    end

    context "merchant account" do
      it "builds a sample notification for a merchant account approved webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::SubMerchantAccountApproved,
          "my_id",
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::SubMerchantAccountApproved)
        expect(notification.merchant_account.id).to eq("my_id")
        expect(notification.merchant_account.status).to eq(Braintree::MerchantAccount::Status::Active)
        expect(notification.merchant_account.master_merchant_account.id).to eq("master_ma_for_my_id")
        expect(notification.merchant_account.master_merchant_account.status).to eq(Braintree::MerchantAccount::Status::Active)
      end

      it "builds a sample notification for a merchant account declined webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::SubMerchantAccountDeclined,
          "my_id",
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::SubMerchantAccountDeclined)
        expect(notification.merchant_account.id).to eq("my_id")
        expect(notification.merchant_account.status).to eq(Braintree::MerchantAccount::Status::Suspended)
        expect(notification.merchant_account.master_merchant_account.id).to eq("master_ma_for_my_id")
        expect(notification.merchant_account.master_merchant_account.status).to eq(Braintree::MerchantAccount::Status::Suspended)
        expect(notification.message).to eq("Credit score is too low")
        expect(notification.errors.for(:merchant_account).on(:base).first.code).to eq(Braintree::ErrorCodes::MerchantAccount::DeclinedOFAC)
      end
    end

    context "subscription" do
      it "builds a sample notification for a subscription billing skipped  webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::SubscriptionBillingSkipped,
          "my_id",
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::SubscriptionBillingSkipped)
        expect(notification.subscription.id).to eq("my_id")
        expect(notification.subscription.transactions.size).to eq(0)
        expect(notification.subscription.discounts.size).to eq(0)
        expect(notification.subscription.add_ons.size).to eq(0)
      end

      it "builds a sample notification for a subscription charged successfully webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::SubscriptionChargedSuccessfully,
          "my_id",
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::SubscriptionChargedSuccessfully)
        expect(notification.subscription.id).to eq("my_id")
        expect(notification.subscription.transactions.size).to eq(1)
        expect(notification.subscription.transactions.first.status).to eq(Braintree::Transaction::Status::SubmittedForSettlement)
        expect(notification.subscription.transactions.first.amount).to eq(BigDecimal("49.99"))
      end

      it "builds a sample notification for a subscription charged unsuccessfully webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::SubscriptionChargedUnsuccessfully,
          "my_id",
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

        expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::SubscriptionChargedUnsuccessfully)
        expect(notification.subscription.id).to eq("my_id")
        expect(notification.subscription.transactions.size).to eq(1)
        expect(notification.subscription.transactions.first.status).to eq(Braintree::Transaction::Status::Failed)
        expect(notification.subscription.transactions.first.amount).to eq(BigDecimal("49.99"))
      end
    end

    it "includes a valid signature" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id",
      )
      expected_signature = Braintree::Digest.hexdigest(Braintree::Configuration.private_key, sample_notification[:bt_payload])

      expect(sample_notification[:bt_signature]).to eq("#{Braintree::Configuration.public_key}|#{expected_signature}")
    end
  end

  context "account_updater_daily_report" do
    it "builds a sample notification for an account_updater_daily_report webhook" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::AccountUpdaterDailyReport,
        "my_id",
      )

      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])

      expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::AccountUpdaterDailyReport)
      expect(notification.account_updater_daily_report.report_url).to eq("link-to-csv-report")
      expect(notification.account_updater_daily_report.report_date).to eq(Date.parse("2016-01-14"))
    end
  end

  context "granted_payment_instrument_update" do
    it "builds a sample notification for a GrantorUpdatedGrantedPaymentMethod webhook" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::GrantorUpdatedGrantedPaymentMethod,
        "my_id",
      )

      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])
      update = notification.granted_payment_instrument_update

      expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::GrantorUpdatedGrantedPaymentMethod)
      expect(update.grant_owner_merchant_id).to eq("vczo7jqrpwrsi2px")
      expect(update.grant_recipient_merchant_id).to eq("cf0i8wgarszuy6hc")
      expect(update.payment_method_nonce).to eq("ee257d98-de40-47e8-96b3-a6954ea7a9a4")
      expect(update.token).to eq("abc123z")
      expect(update.updated_fields).to eq(["expiration-month", "expiration-year"])
    end

    it "builds a sample notification for a RecipientUpdatedGrantedPaymentMethod webhook" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::RecipientUpdatedGrantedPaymentMethod,
        "my_id",
      )

      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])
      update = notification.granted_payment_instrument_update

      expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::RecipientUpdatedGrantedPaymentMethod)
      expect(update.grant_owner_merchant_id).to eq("vczo7jqrpwrsi2px")
      expect(update.grant_recipient_merchant_id).to eq("cf0i8wgarszuy6hc")
      expect(update.payment_method_nonce).to eq("ee257d98-de40-47e8-96b3-a6954ea7a9a4")
      expect(update.token).to eq("abc123z")
      expect(update.updated_fields).to eq(["expiration-month", "expiration-year"])
    end
  end

  context "granted_payment_instrument_revoked" do
    let(:gateway) do
      config = Braintree::Configuration.new(
        :merchant_id => "merchant_id",
        :public_key => "wrong_public_key",
        :private_key => "wrong_private_key",
      )
      Braintree::Gateway.new(config)
    end

    describe "credit cards" do
      it "builds a webhook notification for a granted_payment_instrument_revoked webhook" do
        webhook_xml_response = <<-XML
        <notification>
          <source-merchant-id>12345</source-merchant-id>
          <timestamp type="datetime">2018-10-10T22:46:41Z</timestamp>
          <kind>granted_payment_instrument_revoked</kind>
          <subject>
            <credit-card>
              <bin>555555</bin>
              <card-type>MasterCard</card-type>
              <cardholder-name>Amber Ankunding</cardholder-name>
              <commercial>Unknown</commercial>
              <country-of-issuance>Unknown</country-of-issuance>
              <created-at type="datetime">2018-10-10T22:46:41Z</created-at>
              <customer-id>credit_card_customer_id</customer-id>
              <customer-location>US</customer-location>
              <debit>Unknown</debit>
              <default type="boolean">true</default>
              <durbin-regulated>Unknown</durbin-regulated>
              <expiration-month>06</expiration-month>
              <expiration-year>2020</expiration-year>
              <expired type="boolean">false</expired>
              <global-id>cGF5bWVudG1ldGhvZF8zcHQ2d2hz</global-id>
              <healthcare>Unknown</healthcare>
              <image-url>https://assets.braintreegateway.com/payment_method_logo/mastercard.png?environment=test</image-url>
              <issuing-bank>Unknown</issuing-bank>
              <last-4>4444</last-4>
              <payroll>Unknown</payroll>
              <prepaid>Unknown</prepaid>
              <product-id>Unknown</product-id>
              <subscriptions type="array"/>
              <token>credit_card_token</token>
              <unique-number-identifier>08199d188e37460163207f714faf074a</unique-number-identifier>
              <updated-at type="datetime">2018-10-10T22:46:41Z</updated-at>
              <venmo-sdk type="boolean">false</venmo-sdk>
              <verifications type="array"/>
            </credit-card>
          </subject>
        </notification>
        XML
        attributes = Braintree::Xml.hash_from_xml(webhook_xml_response)
        notification = Braintree::WebhookNotification._new(gateway, attributes[:notification])
        metadata = notification.revoked_payment_method_metadata

        expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::GrantedPaymentInstrumentRevoked)
        expect(metadata.customer_id).to eq("credit_card_customer_id")
        expect(metadata.token).to eq("credit_card_token")
        expect(metadata.revoked_payment_method.class).to eq(Braintree::CreditCard)
      end
    end

    describe "paypal accounts" do
      it "builds a webhook notification for a granted_payment_instrument_revoked webhook" do
        webhook_xml_response = <<-XML
        <notification>
          <source-merchant-id>12345</source-merchant-id>
          <timestamp type="datetime">2018-10-10T22:46:41Z</timestamp>
          <kind>granted_payment_instrument_revoked</kind>
          <subject>
            <paypal-account>
              <billing-agreement-id>billing_agreement_id</billing-agreement-id>
              <created-at type="dateTime">2018-10-11T21:10:33Z</created-at>
              <customer-id>paypal_customer_id</customer-id>
              <default type="boolean">true</default>
              <email>johndoe@example.com</email>
              <global-id>cGF5bWVudG1ldGhvZF9wYXlwYWxfdG9rZW4</global-id>
              <image-url>https://jsdk.bt.local:9000/payment_method_logo/paypal.png?environment=test://assets.braintreegateway.com/payment_method_logo/paypal.png?environment=test</image-url>
              <subscriptions type="array"></subscriptions>
              <token>paypal_token</token>
              <updated-at type="dateTime">2018-10-11T21:10:33Z</updated-at>
              <payer-id>a6a8e1a4</payer-id>
            </paypal-account>
          </subject>
        </notification>
        XML
        attributes = Braintree::Xml.hash_from_xml(webhook_xml_response)
        notification = Braintree::WebhookNotification._new(gateway, attributes[:notification])
        metadata = notification.revoked_payment_method_metadata

        expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::GrantedPaymentInstrumentRevoked)
        expect(metadata.customer_id).to eq("paypal_customer_id")
        expect(metadata.token).to eq("paypal_token")
        expect(metadata.revoked_payment_method.class).to eq(Braintree::PayPalAccount)
      end
    end

    describe "venmo accounts" do
      it "builds a webhook notification for a granted_payment_instrument_revoked webhook" do
        webhook_xml_response = <<-XML
        <notification>
          <source-merchant-id>12345</source-merchant-id>
          <timestamp type="datetime">2018-10-10T22:46:41Z</timestamp>
          <kind>granted_payment_instrument_revoked</kind>
          <subject>
            <venmo-account>
              <created-at type="dateTime">2018-10-11T21:28:37Z</created-at>
              <updated-at type="dateTime">2018-10-11T21:28:37Z</updated-at>
              <default type="boolean">true</default>
              <image-url>https://assets.braintreegateway.com/payment_method_logo/venmo.png?environment=test</image-url>
              <token>venmo_token</token>
              <source-description>Venmo Account: venmojoe</source-description>
              <username>venmojoe</username>
              <venmo-user-id>456</venmo-user-id>
              <subscriptions type="array"/>
              <customer-id>venmo_customer_id</customer-id>
              <global-id>cGF5bWVudG1ldGhvZF92ZW5tb2FjY291bnQ</global-id>
            </venmo-account>
          </subject>
        </notification>
        XML
        attributes = Braintree::Xml.hash_from_xml(webhook_xml_response)
        notification = Braintree::WebhookNotification._new(gateway, attributes[:notification])
        metadata = notification.revoked_payment_method_metadata

        expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::GrantedPaymentInstrumentRevoked)
        expect(metadata.customer_id).to eq("venmo_customer_id")
        expect(metadata.token).to eq("venmo_token")
        expect(metadata.revoked_payment_method.class).to eq(Braintree::VenmoAccount)
      end

      it "builds a sample notification for a GrantedPaymentMethodRevoked webhook" do
        sample_notification = Braintree::WebhookTesting.sample_notification(
          Braintree::WebhookNotification::Kind::GrantedPaymentMethodRevoked,
          "my_id",
        )

        notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])
        expect(notification.kind).to eq Braintree::WebhookNotification::Kind::GrantedPaymentMethodRevoked

        metadata = notification.revoked_payment_method_metadata

        expect(metadata.customer_id).to eq "venmo_customer_id"
        expect(metadata.token).to eq "my_id"
        expect(metadata.revoked_payment_method.class).to eq Braintree::VenmoAccount
      end
    end
  end

  context "payment_method_revoked_by_customer" do
    it "builds a sample notification for a payment_method_revoked_by_customer webhook" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::PaymentMethodRevokedByCustomer,
        "my_payment_method_token",
      )

      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])
      expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::PaymentMethodRevokedByCustomer)

      metadata = notification.revoked_payment_method_metadata
      expect(metadata.token).to eq("my_payment_method_token")
      expect(metadata.revoked_payment_method.class).to eq(Braintree::PayPalAccount)
      expect(metadata.revoked_payment_method.revoked_at).not_to be_nil
    end
  end

  context "local_payment_completed" do
    it "builds a sample notification for a local_payment webhook" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::LocalPaymentCompleted,
        "my_id",
      )

      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])
      expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::LocalPaymentCompleted)

      local_payment_completed = notification.local_payment_completed
      expect(local_payment_completed.payment_id).to eq("PAY-XYZ123")
      expect(local_payment_completed.payer_id).to eq("ABCPAYER")
      expect(local_payment_completed.payment_method_nonce).to eq("ee257d98-de40-47e8-96b3-a6954ea7a9a4")
      expect(local_payment_completed.transaction.id).to eq("my_id")
      expect(local_payment_completed.transaction.status).to eq(Braintree::Transaction::Status::Authorized)
      expect(local_payment_completed.transaction.amount).to eq(49.99)
      expect(local_payment_completed.transaction.order_id).to eq("order4567")
    end
  end

  context "local_payment_expired" do
    it "builds a sample notification for a local_payment_expired webhook" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::LocalPaymentExpired,
        "my_id",
      )

      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])
      expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::LocalPaymentExpired)

      local_payment_expired = notification.local_payment_expired
      expect(local_payment_expired.payment_id).to eq("PAY-XYZ123")
      expect(local_payment_expired.payment_context_id).to eq("cG5b=")
    end
  end

  context "local_payment_funded" do
    it "builds a sample notification for a local_payment_funded webhook" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::LocalPaymentFunded,
        "my_id",
      )
      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])
      expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::LocalPaymentFunded)

      local_payment_funded = notification.local_payment_funded
      expect(local_payment_funded.payment_id).to eq("PAY-XYZ123")
      expect(local_payment_funded.payment_context_id).to eq("cG5b=")
      expect(local_payment_funded.transaction.id).to eq("my_id")
      expect(local_payment_funded.transaction.status).to eq(Braintree::Transaction::Status::Settled)
      expect(local_payment_funded.transaction.amount).to eq(49.99)
      expect(local_payment_funded.transaction.order_id).to eq("order4567")
    end
  end

  context "local_payment_reversed" do
    it "builds a sample notification for a local_payment webhook" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::LocalPaymentReversed,
        "my_id",
      )
      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])
      expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::LocalPaymentReversed)

      local_payment_reversed = notification.local_payment_reversed
      expect(local_payment_reversed.payment_id).to eq("PAY-XYZ123")
    end
  end

  context "payment_method_customer_data_updated" do
    it "builds a sample notification for a payment_method_customer_data_updated webhook" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::PaymentMethodCustomerDataUpdated,
        "my_id",
      )
      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])
      expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::PaymentMethodCustomerDataUpdated)

      payment_method_customer_data_updated = notification.payment_method_customer_data_updated_metadata

      expect(payment_method_customer_data_updated.token).to eq("TOKEN-12345")
      expect(payment_method_customer_data_updated.datetime_updated).to eq("2022-01-01T21:28:37Z")

      enriched_customer_data = payment_method_customer_data_updated.enriched_customer_data
      expect(enriched_customer_data.fields_updated).to eq(["username"])

      profile_data = enriched_customer_data.profile_data
      expect(profile_data.first_name).to eq("John")
      expect(profile_data.last_name).to eq("Doe")
      expect(profile_data.username).to eq("venmo_username")
      expect(profile_data.phone_number).to eq("1231231234")
      expect(profile_data.email).to eq("john.doe@paypal.com")
    end
  end

  describe "parse" do
    it "raises InvalidSignature error when the signature is nil" do
      expect do
        Braintree::WebhookNotification.parse(nil, "payload")
      end.to raise_error(Braintree::InvalidSignature, "signature cannot be nil")
    end

    it "raises InvalidSignature error when the payload is nil" do
      expect do
        Braintree::WebhookNotification.parse("signature", nil)
      end.to raise_error(Braintree::InvalidSignature, "payload cannot be nil")
    end

    it "raises InvalidSignature error when the signature is completely invalid" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id",
      )

      expect do
        Braintree::WebhookNotification.parse("not a valid signature", sample_notification[:bt_payload])
      end.to raise_error(Braintree::InvalidSignature)
    end

    it "raises InvalidSignature error with a message when the public key is not found" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id",
      )

      config = Braintree::Configuration.new(
        :merchant_id => "merchant_id",
        :public_key => "wrong_public_key",
        :private_key => "wrong_private_key",
      )
      gateway = Braintree::Gateway.new(config)

      expect do
        gateway.webhook_notification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])
      end.to raise_error(Braintree::InvalidSignature, /no matching public key/)
    end

    it "raises InvalidSignature error if the payload has been changed" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id",
      )

      expect do
        Braintree::WebhookNotification.parse(sample_notification[:bt_signature], "badstuff" + sample_notification[:bt_payload])
      end.to raise_error(Braintree::InvalidSignature, /signature does not match payload - one has been modified/)
    end

    it "raises InvalidSignature error with a message complaining about invalid characters" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id",
      )

      expect do
        Braintree::WebhookNotification.parse(sample_notification[:bt_signature], "^& bad ,* chars @!" + sample_notification[:bt_payload])
      end.to raise_error(Braintree::InvalidSignature, /payload contains illegal characters/)
    end

    it "allows all valid characters" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id",
      )

      sample_notification[:bt_payload] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+=/\n"

      begin
        Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload])
      rescue Braintree::InvalidSignature => e
        exception = e
      end

      expect(exception.message).not_to match(/payload contains illegal characters/)
    end

    it "retries a payload with a newline" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        "my_id",
      )

      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload].rstrip)

      expect(notification.kind).to eq(Braintree::WebhookNotification::Kind::SubscriptionWentPastDue)
      expect(notification.subscription.id).to eq("my_id")
      expect(notification.timestamp).to be_within(10).of(Time.now.utc)
    end
  end

  describe "check?" do
    it "returns true for check webhook kinds" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::Check,
        nil,
      )

      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload].rstrip)

      expect(notification.check?).to eq(true)
    end

    it "returns false for non-check webhook kinds" do
      sample_notification = Braintree::WebhookTesting.sample_notification(
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue,
        nil,
      )

      notification = Braintree::WebhookNotification.parse(sample_notification[:bt_signature], sample_notification[:bt_payload].rstrip)

      expect(notification.check?).to eq(false)
    end
  end

  describe "self.verify" do
    it "creates a verification string" do
      response = Braintree::WebhookNotification.verify("20f9f8ed05f77439fe955c977e4c8a53")
      expect(response).to eq("integration_public_key|d9b899556c966b3f06945ec21311865d35df3ce4")
    end

    it "raises InvalidChallenge error with a message complaining about invalid characters" do
      challenge = "bad challenge"

      expect do
        Braintree::WebhookNotification.verify(challenge)
      end.to raise_error(Braintree::InvalidChallenge, /challenge contains non-hex characters/)
    end
  end
end
