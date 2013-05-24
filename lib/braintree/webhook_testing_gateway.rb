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
      if kind != Braintree::WebhookNotification::Kind::PartnerConnectionCreated
        _subscription_sample_xml(data)
      else
        _partner_connection_sample_xml(data)
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

    def _partner_connection_sample_xml(data)
      <<-XML
        <partner_connection>
          <merchant_public_id>#{data[:merchant_public_id]}</merchant_public_id>
          <public_key>#{data[:public_key]}</public_key>
          <private_key>#{data[:private_key]}</private_key>
          <partnership_user_id>#{data[:partnership_user_id]}</partnership_user_id>
        </partner_connection>
      XML
    end
  end
end
