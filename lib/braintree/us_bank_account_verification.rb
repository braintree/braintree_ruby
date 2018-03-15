module Braintree
  class UsBankAccountVerification
    include BaseModule
    include Braintree::Util::IdEquality

    module Status
      Failed = "failed"
      GatewayRejected = "gateway_rejected"
      ProcessorDeclined = "processor_declined"
      Verified = "verified"

      All = [Failed, GatewayRejected, ProcessorDeclined, Verified]
    end

    module VerificationMethod
      IndependentCheck = "independent_check"
      NetworkCheck = "network_check"
      TokenizedCheck = "tokenized_check"

      All = [IndependentCheck, NetworkCheck, TokenizedCheck]
    end

    attr_reader :id
    attr_reader :status
    attr_reader :verification_determined_at
    attr_reader :verification_method
    attr_reader :processor_response_code
    attr_reader :processor_response_text
    attr_reader :merchant_account_id
    attr_reader :gateway_rejection_reason
    attr_reader :us_bank_account
    attr_reader :created_at

    def initialize(attributes) # :nodoc:
      set_instance_variables_from_hash(attributes)
    end

    def inspect # :nodoc:
      attr_order = [
        :status,
        :processor_response_code,
        :processor_response_text,
        :merchant_account_id,
        :gateway_rejection_reason,
        :id,
        :us_bank_account,
        :verification_method,
        :verification_determined_at,
        :created_at
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

    def self.find(*args)
      Configuration.gateway.us_bank_account_verification.find(*args)
    end

    def self.search(&block)
      Configuration.gateway.us_bank_account_verification.search(&block)
    end
  end
end
