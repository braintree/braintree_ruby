module Braintree
  class WebhookNotificationGateway # :nodoc:
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def parse(signature_string, payload)
      _verify_signature(signature_string, payload)
      attributes = Xml.hash_from_xml(Base64.decode64(payload))
      WebhookNotification._new(@gateway, attributes[:notification])
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

    def _verify_signature(signature, payload)
      public_key, signature = _matching_signature_pair(signature)
      payload_signature = Braintree::Digest.hexdigest(@config.private_key, payload)

      raise InvalidSignature if public_key.nil?
      raise InvalidSignature unless Braintree::Digest.secure_compare(signature, payload_signature)
    end
  end
end
