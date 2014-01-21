require 'json'

module Braintree
  module ClientToken
    def self.generate(optional_data={})
      data = {
        :public_key => Configuration.public_key,
        :created_at => Time.now.strftime('%Y-%m-%dT%H:%M:%S%z')
      }

      [:customer_id, :proxy_merchant_id].each do |optional_param|
        data[optional_param] = optional_data[optional_param] if optional_data[optional_param]
      end

      [:make_default, :fail_on_duplicate_payment_method, :verify_card].each do |credit_card_option|
        if optional_data[credit_card_option]
          raise ArgumentError.new("cannot specify #{credit_card_option} without a customer_id") unless data[:customer_id]
          data["credit_card[options][#{credit_card_option}]"] = optional_data[credit_card_option]
        end
      end

      signed_data = Configuration.sha256_signature_service.sign(data)

      {
        :authorization_fingerprint => signed_data,
        :client_api_url => Configuration.instantiate.base_merchant_url + "/client_api",
        :auth_url => Configuration.instantiate.auth_url
      }.to_json
    end
  end
end
