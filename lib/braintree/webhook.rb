module Braintree
  module Webhook
    def self.verify(challenge)
      digest = Braintree::Digest.hexdigest(Braintree::Configuration.private_key, challenge)
      "#{Braintree::Configuration.public_key}|#{digest}"
    end
  end
end
