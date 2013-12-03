module Braintree
  module AuthorizationFingerprint
    def self.generate(optional_data={})
      data = {
        :merchant_id => Configuration.merchant_id,
        :public_key => Configuration.public_key,
        :created_at => Time.now
      }

      data[:customer_id] = optional_data[:customer_id] if optional_data[:customer_id]

      [:make_default, :fail_on_duplicate_payment_method, :verify_card].each do |credit_card_option|
        if optional_data[credit_card_option]
          raise ArgumentError.new("cannot specify #{credit_card_option} without a customer_id") unless data[:customer_id]
          data["credit_card[options][#{credit_card_option}]"] = optional_data[credit_card_option]
        end
      end

      Configuration.sha256_signature_service.sign(data)
    end
  end
end