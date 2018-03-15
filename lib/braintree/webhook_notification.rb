require 'ostruct'

module Braintree
  class WebhookNotification
    include BaseModule

    module Kind
      Check = "check"

      Disbursement = "disbursement"
      DisbursementException = "disbursement_exception"

      DisputeOpened = "dispute_opened"
      DisputeLost = "dispute_lost"
      DisputeWon = "dispute_won"

      SubscriptionCanceled = "subscription_canceled"
      SubscriptionChargedSuccessfully = "subscription_charged_successfully"
      SubscriptionChargedUnsuccessfully = "subscription_charged_unsuccessfully"
      SubscriptionExpired = "subscription_expired"
      SubscriptionTrialEnded = "subscription_trial_ended"
      SubscriptionWentActive = "subscription_went_active"
      SubscriptionWentPastDue = "subscription_went_past_due"

      SubMerchantAccountApproved = "sub_merchant_account_approved"
      SubMerchantAccountDeclined = "sub_merchant_account_declined"
      TransactionDisbursed = "transaction_disbursed"
      TransactionSettlementDeclined = "transaction_settlement_declined"
      TransactionSettled = "transaction_settled"
      PartnerMerchantConnected = "partner_merchant_connected"
      PartnerMerchantDisconnected = "partner_merchant_disconnected"
      PartnerMerchantDeclined = "partner_merchant_declined"
      OAuthAccessRevoked = "oauth_access_revoked"

      AccountUpdaterDailyReport = "account_updater_daily_report"

      IdealPaymentComplete = "ideal_payment_complete"
      IdealPaymentFailed = "ideal_payment_failed"

      ConnectedMerchantStatusTransitioned = "connected_merchant_status_transitioned"
      ConnectedMerchantPayPalStatusChanged = "connected_merchant_paypal_status_changed"

      GrantedPaymentInstrumentUpdate = "granted_payment_instrument_update"
    end

    attr_reader :account_updater_daily_report
    attr_reader :connected_merchant_paypal_status_changed
    attr_reader :connected_merchant_status_transitioned
    attr_reader :disbursement
    attr_reader :dispute
    attr_reader :granted_payment_instrument_update
    attr_reader :ideal_payment
    attr_reader :kind
    attr_reader :partner_merchant
    attr_reader :oauth_access_revocation
    attr_reader :source_merchant_id
    attr_reader :subscription
    attr_reader :timestamp
    attr_reader :transaction

    def self.parse(*args)
      Configuration.gateway.webhook_notification.parse(*args)
    end

    def self.verify(*args)
      Configuration.gateway.webhook_notification.verify(*args)
    end

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @error_result = ErrorResult.new(gateway, @subject[:api_error_response]) if @subject.has_key?(:api_error_response)
      @merchant_account = MerchantAccount._new(gateway, @subject[:merchant_account]) if @subject.has_key?(:merchant_account)
      @partner_merchant = OpenStruct.new(@subject[:partner_merchant]) if @subject.has_key?(:partner_merchant)
      @oauth_access_revocation = OpenStruct.new(@subject[:oauth_application_revocation]) if @subject.has_key?(:oauth_application_revocation)
      @subscription = Subscription._new(gateway, @subject[:subscription]) if @subject.has_key?(:subscription)
      @transaction = Transaction._new(gateway, @subject[:transaction]) if @subject.has_key?(:transaction)
      @disbursement = Disbursement._new(gateway, @subject[:disbursement]) if @subject.has_key?(:disbursement)
      @dispute = Dispute._new(@subject[:dispute]) if @subject.has_key?(:dispute)
      @account_updater_daily_report = AccountUpdaterDailyReport._new(@subject[:account_updater_daily_report]) if @subject.has_key?(:account_updater_daily_report)
      @ideal_payment = Braintree::IdealPayment._new(gateway, @subject[:ideal_payment]) if @subject.has_key?(:ideal_payment)
      @connected_merchant_status_transitioned = ConnectedMerchantStatusTransitioned._new(@subject[:connected_merchant_status_transitioned]) if @subject.has_key?(:connected_merchant_status_transitioned)
      @connected_merchant_paypal_status_changed = ConnectedMerchantPayPalStatusChanged._new(@subject[:connected_merchant_paypal_status_changed]) if @subject.has_key?(:connected_merchant_paypal_status_changed)
      @granted_payment_instrument_update = GrantedPaymentInstrumentUpdate._new(@subject[:granted_payment_instrument_update]) if @subject.has_key?(:granted_payment_instrument_update)
    end

    def merchant_account
      @error_result.nil? ? @merchant_account : @error_result.merchant_account
    end

    def errors
      @error_result.errors if @error_result
    end

    def message
      @error_result.message if @error_result
    end

    def check?
      !!@subject[:check]
    end

    class << self
      protected :new
      def _new(*args) # :nodoc:
        self.new *args
      end
    end
  end
end
