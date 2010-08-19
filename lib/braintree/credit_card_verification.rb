module Braintree
  # See http://www.braintreepaymentsolutions.com/docs/ruby/general/card_verification
  class CreditCardVerification
    include BaseModule

    module Status
      FAILED = 'failed'
      GATEWAY_REJECTED = 'gateway_rejected'
      PROCESSOR_DECLINED = 'processor_declined'
      VERIFIED = 'verified'
    end

    attr_reader :avs_error_response_code, :avs_postal_code_response_code, :avs_street_address_response_code,
      :cvv_response_code, :merchant_account_id, :processor_response_code, :processor_response_text, :status,
      :gateway_rejection_reason

    def initialize(attributes) # :nodoc:
      set_instance_variables_from_hash(attributes)
    end

    def inspect # :nodoc:
      attr_order = [
        :status, :processor_response_code, :processor_response_text,
        :cvv_response_code, :avs_error_response_code,
        :avs_postal_code_response_code, :avs_street_address_response_code,
        :merchant_account_id, :gateway_rejection_reason
      ]
      formatted_attrs = attr_order.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<#{self.class} #{formatted_attrs.join(", ")}>"
    end

    class << self
      protected :new
    end

    def self._new(*args) # :nodoc:
      self.new *args
    end
  end
end
