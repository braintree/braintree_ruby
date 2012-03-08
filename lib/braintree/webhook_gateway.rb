module Braintree
  class WebhookGateway # :nodoc:
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def parse(signature_string, payload)
      _verify_signature(signature_string, payload)
      attributes = Xml.hash_from_xml(Base64.decode64(payload))
      Notification._new(@gateway, attributes[:notification])
    end

    def sample_notification(kind, id)
      payload = Base64.encode64(_sample_xml(kind, id))
      signature_string = "#{@config.public_key}|#{Braintree::Digest.hexdigest(Braintree::Configuration.private_key, payload)}"
      return signature_string, payload
    end

    def verify(challenge)
      digest = Braintree::Digest.hexdigest(@config.private_key, challenge)
      "#{@config.public_key}|#{digest}"
    end

    def _matching_signature_pair(signature_string)
      signature_pairs = signature_string.split("&")
      valid_pairs = signature_pairs.select { |pair| pair.include?("|") }.map { |pair| pair.split("|") }

      valid_pairs.detect do |public_key, signature|
        public_key == @config.public_key
      end
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

    def _verify_signature(signature, payload)
      matching_pair = _matching_signature_pair(signature)

      raise InvalidSignature if matching_pair.nil?
      raise InvalidSignature unless matching_pair.last == Braintree::Digest.hexdigest(@config.private_key, payload)
    end
  end
end
