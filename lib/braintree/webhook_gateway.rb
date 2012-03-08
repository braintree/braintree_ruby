module Braintree
  class WebhookGateway # :nodoc:
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def parse(signature, payload)
      attributes = Xml.hash_from_xml(Base64.decode64(payload))
      Notification._new(@gateway, attributes[:notification])
    end

    def sample_notification(kind, id)
      payload = Base64.encode64(_sample_xml(kind, id))
      signature = nil

      return signature, payload
    end

    def verify(challenge)
      digest = Braintree::Digest.hexdigest(@config.private_key, challenge)
      "#{@config.public_key}|#{digest}"
    end

    def _sample_xml(kind, id)
      <<-XML
        <notification>
          <timestamp>#{Time.now}</timestamp>
          <kind>#{kind}</kind>
          #{_subscription_sample_xml(kind, id)}
        </notification>
      XML
    end

    def _subscription_sample_xml(kind, id)
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
  end
end
