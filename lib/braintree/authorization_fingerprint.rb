module Braintree
  module AuthorizationFingerprint
    def self.generate(optional_data={})
      data = {
        :merchant_id => Configuration.merchant_id,
        :public_key => Configuration.public_key,
        :created_at => Time.now
      }

      Configuration.signature_service.sign(optional_data.merge(data))
    end
  end
end
