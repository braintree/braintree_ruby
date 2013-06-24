module Braintree
  class WebhookTestingGateway # :nodoc:
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def sample_notification(kind, data)
      data = {:id => data} unless data.is_a? Hash

      payload = Base64.encode64(_sample_xml(kind, data))
      signature_string = "#{Braintree::Configuration.public_key}|#{Braintree::Digest.hexdigest(Braintree::Configuration.private_key, payload)}"

      return signature_string, payload
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

    def _subject_sample_xml(kind, data)
      case kind
      when Braintree::WebhookNotification::Kind::PartnerUserCreated
        _partner_credentials_sample_xml(data)
      when Braintree::WebhookNotification::Kind::SubMerchantAccountApproved
        _merchant_account_sample_xml(data)
      when Braintree::WebhookNotification::Kind::SubMerchantAccountDeclined
        _merchant_account_declined_sample_xml(data)
      when Braintree::WebhookNotification::Kind::TransactionsDisbursed
        _transactions_disbursed_sample_xml(data)
      else
        _subscription_sample_xml(data)
      end
    end

    def _subscription_sample_xml(data)

      <<-XML
        <subscription>
          <id>#{data[:id]}</id>
          <transactions type="array">
          </transactions>
          <add_ons type="array">
          </add_ons>
          <discounts type="array">
          </discounts>
        </subscription>
      XML
    end

    def _partner_credentials_sample_xml(data)

      <<-XML
        <partner_credentials>
          <merchant_public_id>#{data[:merchant_public_id]}</merchant_public_id>
          <public_key>#{data[:public_key]}</public_key>
          <private_key>#{data[:private_key]}</private_key>
          <partner_user_id>#{data[:partner_user_id]}</partner_user_id>
        </partner_credentials>
      XML
    end

    def _merchant_account_sample_xml(data)

      <<-XML
        <merchant_account>
          <id>#{data[:id]}</id>
          <master_merchant_account>
            <id>#{data[:master_merchant_account][:id]}</id>
            <status>#{data[:master_merchant_account][:status]}</status>
          </master_merchant_account>
          <status>#{data[:status]}</status>
        </merchant_account>
      XML
    end

    def _merchant_account_declined_sample_xml(data)

      <<-XML
        <api-error-response>
          <message>#{data[:message]}</message>
          <errors>
            <merchant-account>
              <errors type="array">
                #{_errors_sample_xml(data[:errors])}
              </errors>
            </merchant-account>
          </errors>
          #{_merchant_account_sample_xml(data[:merchant_account])}
        </api-error-response>
      XML
    end

    def _transactions_disbursed_sample_xml(data)

      <<-XML
        <transaction-ids type="array">
          #{_ids_string(data[:transaction_ids])}
        </transaction-ids>
      XML
    end

    def _ids_string(ids)
      ids.map { |id| "<id>#{id}</id>" }.join("\n")
    end

    def _errors_sample_xml(errors)
      errors.map { |error| _error_sample_xml(error) }.join("\n")
    end

    def _error_sample_xml(error)

      <<-XML
        <error>
          <attribute>#{error[:attribute]}</attribute>
          <code>#{error[:code]}</code>
          <message>#{error[:message]}</message>
        </error>
      XML
    end
  end
end
