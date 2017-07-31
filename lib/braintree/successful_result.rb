module Braintree
  class SuccessfulResult
    include BaseModule

    attr_reader :address, :credit_card, :customer, :document_upload, :merchant_account, :payment_method, :settlement_batch_summary, :subscription, :new_transaction, :transaction, :payment_method_nonce, :credentials, :merchant, :supported_networks, :paypal_account, :merchant_accounts, :disputes, :evidence, :apple_pay_options

    def initialize(attributes = {}) # :nodoc:
      @attrs = attributes.keys
      attributes.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    def inspect # :nodoc:
      inspected_attributes = @attrs.map { |attr| "#{attr}:#{send(attr).inspect}" }
      "#<#{self.class} #{inspected_attributes.join(" ")}>"
    end

    def success?
      true
    end
  end
end
