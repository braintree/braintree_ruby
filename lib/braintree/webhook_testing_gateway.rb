module Braintree
  class WebhookTestingGateway # :nodoc:
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
      @config.assert_has_access_token_or_keys
    end

    def sample_notification(kind, id)
      payload = Base64.encode64(_sample_xml(kind, id))
      signature_string = "#{@config.public_key}|#{Braintree::Digest.hexdigest(@config.private_key, payload)}"

      return {:bt_signature => signature_string, :bt_payload => payload}
    end

    def _sample_xml(kind, data)
      <<-XML
        <notification>
          <timestamp type="datetime">#{Time.now.utc.iso8601}</timestamp>
          <kind>#{kind}</kind>
          <subject>
            #{_subject_sample_xml(kind, data)}
          </subject>
        </notification>
      XML
    end

    def _subject_sample_xml(kind, id)
      case kind
      when Braintree::WebhookNotification::Kind::Check
        _check
      when Braintree::WebhookNotification::Kind::DisputeOpened
        _dispute_opened_sample_xml(id)
      when Braintree::WebhookNotification::Kind::DisputeLost
        _dispute_lost_sample_xml(id)
      when Braintree::WebhookNotification::Kind::DisputeWon
        _dispute_won_sample_xml(id)
      when Braintree::WebhookNotification::Kind::PartnerMerchantConnected
        _partner_merchant_connected_sample_xml(id)
      when Braintree::WebhookNotification::Kind::PartnerMerchantDisconnected
        _partner_merchant_disconnected_sample_xml(id)
      when Braintree::WebhookNotification::Kind::PartnerMerchantDeclined
        _partner_merchant_declined_sample_xml(id)
      when Braintree::WebhookNotification::Kind::SubMerchantAccountApproved
        _merchant_account_approved_sample_xml(id)
      when Braintree::WebhookNotification::Kind::SubMerchantAccountDeclined
        _merchant_account_declined_sample_xml(id)
      when Braintree::WebhookNotification::Kind::TransactionDisbursed
        _transaction_disbursed_sample_xml(id)
      when Braintree::WebhookNotification::Kind::TransactionSettled
        _transaction_settled_sample_xml(id)
      when Braintree::WebhookNotification::Kind::TransactionSettlementDeclined
        _transaction_settlement_declined_sample_xml(id)
      when Braintree::WebhookNotification::Kind::DisbursementException
        _disbursement_exception_sample_xml(id)
      when Braintree::WebhookNotification::Kind::Disbursement
        _disbursement_sample_xml(id)
      when Braintree::WebhookNotification::Kind::SubscriptionChargedSuccessfully
        _subscription_charged_successfully(id)
      when Braintree::WebhookNotification::Kind::AccountUpdaterDailyReport
        _account_updater_daily_report_sample_xml(id)
      when Braintree::WebhookNotification::Kind::ConnectedMerchantStatusTransitioned
        _auth_status_transitioned_sample_xml(id)
      when Braintree::WebhookNotification::Kind::ConnectedMerchantPayPalStatusChanged
        _auth_paypal_status_changed_sample_xml(id)
      when Braintree::WebhookNotification::Kind::IdealPaymentComplete
        _ideal_payment_complete_sample_xml(id)
      when Braintree::WebhookNotification::Kind::IdealPaymentFailed
        _ideal_payment_failed_sample_xml(id)
      else
        _subscription_sample_xml(id)
      end
    end

    def _check

      <<-XML
        <check type="boolean">true</check>
      XML
    end

    def _subscription_charged_successfully(id)

      <<-XML
        <subscription>
          <id>#{id}</id>
          <transactions type="array">
            <transaction>
              <status>submitted_for_settlement</status>
              <amount>49.99</amount>
            </transaction>
          </transactions>
          <add_ons type="array">
          </add_ons>
          <discounts type="array">
          </discounts>
        </subscription>
      XML
    end

    def _subscription_sample_xml(id)

      <<-XML
        <subscription>
          <id>#{id}</id>
          <transactions type="array">
          </transactions>
          <add_ons type="array">
          </add_ons>
          <discounts type="array">
          </discounts>
        </subscription>
      XML
    end

    def _partner_merchant_connected_sample_xml(data)

      <<-XML
        <partner-merchant>
          <merchant-public-id>public_id</merchant-public-id>
          <public-key>public_key</public-key>
          <private-key>private_key</private-key>
          <partner-merchant-id>abc123</partner-merchant-id>
          <client-side-encryption-key>cse_key</client-side-encryption-key>
        </partner-merchant>
      XML
    end

    def _partner_merchant_disconnected_sample_xml(data)

      <<-XML
        <partner-merchant>
          <partner-merchant-id>abc123</partner-merchant-id>
        </partner-merchant>
      XML
    end

    def _partner_merchant_declined_sample_xml(data)

      <<-XML
        <partner-merchant>
          <partner-merchant-id>abc123</partner-merchant-id>
        </partner-merchant>
      XML
    end

    def _merchant_account_approved_sample_xml(id)

      <<-XML
        <merchant_account>
          <id>#{id}</id>
          <master_merchant_account>
            <id>master_ma_for_#{id}</id>
            <status>active</status>
          </master_merchant_account>
          <status>active</status>
        </merchant_account>
      XML
    end

    def _merchant_account_declined_sample_xml(id)

      <<-XML
          <api-error-response>
              <message>Credit score is too low</message>
              <errors type="array"/>
                  <merchant-account>
                      <errors type="array">
                          <error>
                              <code>82621</code>
                              <message>Credit score is too low</message>
                              <attribute type="symbol">base</attribute>
                          </error>
                      </errors>
                  </merchant-account>
              </errors>
              <merchant-account>
                  <id>#{id}</id>
                  <status>suspended</status>
                  <master-merchant-account>
                      <id>master_ma_for_#{id}</id>
                      <status>suspended</status>
                  </master-merchant-account>
              </merchant-account>
          </api-error-response>
      XML
    end

    def _transaction_disbursed_sample_xml(id)

      <<-XML
        <transaction>
          <id>#{id}</id>
          <amount>100</amount>
          <disbursement-details>
            <disbursement-date type="date">2013-07-09</disbursement-date>
          </disbursement-details>
        </transaction>
      XML
    end

    def _transaction_settled_sample_xml(id)
      <<-XML
        <transaction>
          <id>#{id}</id>
          <status>settled</status>
          <type>sale</type>
          <currency-iso-code>USD</currency-iso-code>
          <amount>100.00</amount>
          <merchant-account-id>ogaotkivejpfayqfeaimuktty</merchant-account-id>
          <payment-instrument-type>us_bank_account</payment-instrument-type>
          <us-bank-account>
            <routing-number>123456789</routing-number>
            <last-4>1234</last-4>
            <account-type>checking</account-type>
            <account-holder-name>Dan Schulman</account-holder-name>
          </us-bank-account>
        </transaction>
      XML
    end

    def _transaction_settlement_declined_sample_xml(id)
      <<-XML
        <transaction>
          <id>#{id}</id>
          <status>settlement_declined</status>
          <type>sale</type>
          <currency-iso-code>USD</currency-iso-code>
          <amount>100.00</amount>
          <merchant-account-id>ogaotkivejpfayqfeaimuktty</merchant-account-id>
          <payment-instrument-type>us_bank_account</payment-instrument-type>
          <us-bank-account>
            <routing-number>123456789</routing-number>
            <last-4>1234</last-4>
            <account-type>checking</account-type>
            <account-holder-name>Dan Schulman</account-holder-name>
          </us-bank-account>
        </transaction>
      XML
    end

    def _dispute_opened_sample_xml(id)

      <<-XML
        <dispute>
          <amount>250.00</amount>
          <currency-iso-code>USD</currency-iso-code>
          <received-date type="date">2014-03-01</received-date>
          <reply-by-date type="date">2014-03-21</reply-by-date>
          <kind>chargeback</kind>
          <status>open</status>
          <reason>fraud</reason>
          <id>#{id}</id>
          <transaction>
            <id>#{id}</id>
            <amount>250.00</amount>
          </transaction>
          <date-opened type=\"date\">2014-03-21</date-opened>
        </dispute>
      XML
    end

    def _dispute_lost_sample_xml(id)

      <<-XML
        <dispute>
          <amount>250.00</amount>
          <currency-iso-code>USD</currency-iso-code>
          <received-date type="date">2014-03-01</received-date>
          <reply-by-date type="date">2014-03-21</reply-by-date>
          <kind>chargeback</kind>
          <status>lost</status>
          <reason>fraud</reason>
          <id>#{id}</id>
          <transaction>
            <id>#{id}</id>
            <amount>250.00</amount>
          </transaction>
          <date-opened type=\"date\">2014-03-21</date-opened>
        </dispute>
      XML
    end

    def _dispute_won_sample_xml(id)

      <<-XML
        <dispute>
          <amount>250.00</amount>
          <currency-iso-code>USD</currency-iso-code>
          <received-date type="date">2014-03-01</received-date>
          <reply-by-date type="date">2014-03-21</reply-by-date>
          <kind>chargeback</kind>
          <status>won</status>
          <reason>fraud</reason>
          <id>#{id}</id>
          <transaction>
            <id>#{id}</id>
            <amount>250.00</amount>
          </transaction>
          <date-opened type=\"date\">2014-03-21</date-opened>
          <date-won type=\"date\">2014-03-22</date-won>
        </dispute>
      XML
    end

    def _disbursement_exception_sample_xml(id)

      <<-XML
        <disbursement>
          <id>#{id}</id>
          <transaction-ids type="array">
            <item>afv56j</item>
            <item>kj8hjk</item>
          </transaction-ids>
          <success type="boolean">false</success>
          <retry type="boolean">false</retry>
          <merchant-account>
            <id>merchant_account_token</id>
            <currency-iso-code>USD</currency-iso-code>
            <sub-merchant-account type="boolean">false</sub-merchant-account>
            <status>active</status>
          </merchant-account>
          <amount>100.00</amount>
          <disbursement-date type="date">2014-02-10</disbursement-date>
          <exception-message>bank_rejected</exception-message>
          <follow-up-action>update_funding_information</follow-up-action>
        </disbursement>
      XML
    end

    def _disbursement_sample_xml(id)

      <<-XML
        <disbursement>
          <id>#{id}</id>
          <transaction-ids type="array">
            <item>afv56j</item>
            <item>kj8hjk</item>
          </transaction-ids>
          <success type="boolean">true</success>
          <retry type="boolean">false</retry>
          <merchant-account>
            <id>merchant_account_token</id>
            <currency-iso-code>USD</currency-iso-code>
            <sub-merchant-account type="boolean">false</sub-merchant-account>
            <status>active</status>
          </merchant-account>
          <amount>100.00</amount>
          <disbursement-date type="date">2014-02-10</disbursement-date>
          <exception-message nil="true"/>
          <follow-up-action nil="true"/>
        </disbursement>
      XML
    end

    def _account_updater_daily_report_sample_xml(id)

      <<-XML
        <account-updater-daily-report>
          <report-date type="date">2016-01-14</report-date>
          <report-url>link-to-csv-report</report-url>
        </account-updater-daily-report>
      XML
    end

    def _auth_status_transitioned_sample_xml(id)
      <<-XML
        <connected-merchant-status-transitioned>
          <merchant-public-id>#{id}</merchant-public-id>
          <status>new_status</status>
          <oauth-application-client-id>oauth_application_client_id</oauth-application-client-id>
        </connected-merchant-status-transitioned>
      XML
    end

    def _auth_paypal_status_changed_sample_xml(id)
      <<-XML
        <connected-merchant-paypal-status-changed>
          <oauth-application-client-id>oauth_application_client_id</oauth-application-client-id>
          <merchant-public-id>#{id}</merchant-public-id>
          <action>link</action>
        </connected-merchant-paypal-status-changed>
        XML
    end

    def _ideal_payment_complete_sample_xml(id)

      <<-XML
        <ideal-payment>
          <id>#{id}</id>
          <status>COMPLETE</status>
          <issuer>ABCISSUER</issuer>
          <order-id>ORDERABC</order-id>
          <currency>EUR</currency>
          <amount>10.00</amount>
          <created-at>2016-11-29T23:27:34.547Z</created-at>
          <iban-bank-account>
            <created-at>2016-11-29T23:27:36.386Z</created-at>
            <description>DESCRIPTION ABC</description>
            <bic>XXXXNLXX</bic>
            <iban-country>11</iban-country>
            <iban-account-number-last-4>0000</iban-account-number-last-4>
            <masked-iban>NL************0000</masked-iban>
            <account-holder-name>Account Holder</account-holder-name>
          </iban-bank-account>
          <approval-url>https://example.com</approval-url>
          <ideal-transaction-id>1234567890</ideal-transaction-id>
        </ideal-payment>
      XML
    end

    def _ideal_payment_failed_sample_xml(id)

      <<-XML
        <ideal-payment>
          <id>#{id}</id>
          <status>FAILED</status>
          <issuer>ABCISSUER</issuer>
          <order-id>ORDERABC</order-id>
          <currency>EUR</currency>
          <amount>10.00</amount>
          <created-at>2016-11-29T23:27:34.547Z</created-at>
          <approval-url>https://example.com</approval-url>
          <ideal-transaction-id>1234567890</ideal-transaction-id>
        </ideal-payment>
      XML
    end
  end
end
