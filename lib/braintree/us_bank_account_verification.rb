module Braintree
  class UsBankAccountVerification
    include BaseModule
    include Braintree::Util::IdEquality

    module Status
      Failed = "failed"
      GatewayRejected = "gateway_rejected"
      ProcessorDeclined = "processor_declined"
      Verified = "verified"
      Pending = "pending"

      All = [Failed, GatewayRejected, ProcessorDeclined, Verified, Pending]
    end

    module VerificationMethod
      IndependentCheck = "independent_check"
      NetworkCheck = "network_check"
      TokenizedCheck = "tokenized_check"
      MicroTransfers = "micro_transfers"

      All = [IndependentCheck, NetworkCheck, TokenizedCheck, MicroTransfers]
    end

    module VerificationAddOns
      CustomerVerification = "customer_verification"

      All = [CustomerVerification]
    end

    attr_reader :additional_processor_response
    attr_reader :created_at
    attr_reader :gateway_rejection_reason
    attr_reader :id
    attr_reader :merchant_account_id
    attr_reader :processor_response_code
    attr_reader :processor_response_text
    attr_reader :status
    attr_reader :us_bank_account
    attr_reader :verification_determined_at
    attr_reader :verification_method

    def initialize(attributes)
      set_instance_variables_from_hash(attributes)
    end

    def inspect
      attr_order = [
        :additional_processor_response,
        :created_at,
        :gateway_rejection_reason,
        :id,
        :merchant_account_id,
        :processor_response_code,
        :processor_response_text,
        :status,
        :us_bank_account,
        :verification_determined_at,
        :verification_method
      ]

      formatted_attrs = attr_order.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end

      "#<#{self.class} #{formatted_attrs.join(", ")}>"
    end

    class << self
      protected :new
    end

    def self._new(*args)
      self.new(*args)
    end

    def self.confirm_micro_transfer_amounts(*args)
      Configuration.gateway.us_bank_account_verification.confirm_micro_transfer_amounts(*args)
    end

    def self.find(*args)
      Configuration.gateway.us_bank_account_verification.find(*args)
    end

    def self.search(&block)
      Configuration.gateway.us_bank_account_verification.search(&block)
    end
  end
end
