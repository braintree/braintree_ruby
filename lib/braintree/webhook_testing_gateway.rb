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
      when Braintree::WebhookNotification::Kind::DisbursementException
        _disbursement_exception_sample_xml(id)
      when Braintree::WebhookNotification::Kind::Disbursement
        _disbursement_sample_xml(id)
      when Braintree::WebhookNotification::Kind::SubscriptionChargedSuccessfully
        _subscription_charged_successfully(id)
      else
        _subscription_sample_xml(id)
      end
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
              <errors>
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
  end
end
