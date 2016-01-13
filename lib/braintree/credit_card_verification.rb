module Braintree
  class CreditCardVerification
    include BaseModule

    module Status
      Failed = 'failed'
      GatewayRejected = 'gateway_rejected'
      ProcessorDeclined = 'processor_declined'
      Verified = 'verified'

      All = [Failed, GatewayRejected, ProcessorDeclined, Verified]
    end

    attr_reader :avs_error_response_code, :avs_postal_code_response_code, :avs_street_address_response_code,
      :cvv_response_code, :merchant_account_id, :processor_response_code, :processor_response_text, :status,
      :id, :gateway_rejection_reason, :credit_card, :billing, :created_at, :risk_data

    def initialize(attributes) # :nodoc:
      set_instance_variables_from_hash(attributes)
      @risk_data = RiskData.new(attributes[:risk_data]) if attributes[:risk_data]
    end

    def inspect # :nodoc:
      attr_order = [
        :status, :processor_response_code, :processor_response_text,
        :cvv_response_code, :avs_error_response_code,
        :avs_postal_code_response_code, :avs_street_address_response_code,
        :merchant_account_id, :gateway_rejection_reason, :id, :credit_card, :billing, :created_at
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

    def self.find(id)
      Configuration.gateway.verification.find(id)
    end

    def self.search(&block)
      Configuration.gateway.verification.search(&block)
    end

    def self.create(attributes)
      Util.verify_keys(CreditCardVerificationGateway._create_signature, attributes)
      Configuration.gateway.verification.create(attributes)
    end

    def ==(other)
      return false unless other.is_a?(CreditCardVerification)
      id == other.id
    end
  end
end
