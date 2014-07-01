require 'json'

module Braintree
  module ClientToken
    def self.generate(options={})
      _validate_options(options)

      options[:version] ||= 2

      Configuration.gateway.client_token.generate(options)
    end

    def self._validate_options(options)
      [:make_default, :fail_on_duplicate_payment_method, :verify_card].each do |credit_card_option|
        if options[credit_card_option]
          raise ArgumentError.new("cannot specify #{credit_card_option} without a customer_id") unless options[:customer_id]
        end
      end
    end
  end
end
