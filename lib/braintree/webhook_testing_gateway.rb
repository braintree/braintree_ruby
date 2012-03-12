module Braintree
  class WebhookTestingGateway # :nodoc:
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def sample_notification(kind, id)
      payload = Base64.encode64(_sample_xml(kind, id))
      signature_string = "#{Braintree::Configuration.public_key}|#{Braintree::Digest.hexdigest(Braintree::Configuration.private_key, payload)}"

      return signature_string, payload
    end

    def _sample_xml(kind, id)
      <<-XML
        <notification>
          <timestamp>#{Time.now}</timestamp>
          <kind>#{kind}</kind>
          <subject>
            #{_subscription_sample_xml(kind, id)}
          </subject>
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
