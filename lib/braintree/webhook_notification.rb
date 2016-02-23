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
      PartnerMerchantConnected = "partner_merchant_connected"
      PartnerMerchantDisconnected = "partner_merchant_disconnected"
      PartnerMerchantDeclined = "partner_merchant_declined"

      AccountUpdaterDailyReport = "account_updater_daily_report"
    end

    attr_reader :subscription, :kind, :timestamp, :transaction, :partner_merchant, :disbursement, :dispute, :account_updater_daily_report

    def self.parse(signature, payload)
      Configuration.gateway.webhook_notification.parse(signature, payload)
    end

    def self.verify(challenge)
      Configuration.gateway.webhook_notification.verify(challenge)
    end

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @error_result = ErrorResult.new(gateway, @subject[:api_error_response]) if @subject.has_key?(:api_error_response)
      @merchant_account = MerchantAccount._new(gateway, @subject[:merchant_account]) if @subject.has_key?(:merchant_account)
      @partner_merchant = OpenStruct.new(@subject[:partner_merchant]) if @subject.has_key?(:partner_merchant)
      @subscription = Subscription._new(gateway, @subject[:subscription]) if @subject.has_key?(:subscription)
      @transaction = Transaction._new(gateway, @subject[:transaction]) if @subject.has_key?(:transaction)
      @disbursement = Disbursement._new(gateway, @subject[:disbursement]) if @subject.has_key?(:disbursement)
      @dispute = Dispute._new(@subject[:dispute]) if @subject.has_key?(:dispute)
      @account_updater_daily_report = AccountUpdaterDailyReport._new(@subject[:account_updater_daily_report]) if @subject.has_key?(:account_updater_daily_report)
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
