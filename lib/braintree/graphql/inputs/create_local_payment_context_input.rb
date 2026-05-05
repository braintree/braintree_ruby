module Braintree
  class CreateLocalPaymentContextInput
    include BaseModule

    attr_reader :amount
    attr_reader :attrs
    attr_reader :cancel_url
    attr_reader :country_code
    attr_reader :expiry_date
    attr_reader :merchant_account_id
    attr_reader :order_id
    attr_reader :payer_info
    attr_reader :return_url
    attr_reader :type

    def initialize(attributes)
      @attrs = attributes.keys
      set_instance_variables_from_hash(attributes)
      @amount = attributes[:amount] ? MonetaryAmountInput.new(attributes[:amount]) : nil
      @payer_info = attributes[:payer_info] ? PayerInfoInput.new(attributes[:payer_info]) : nil
    end

    def inspect
      inspected_attributes = @attrs.map { |attr| "#{attr}:#{send(attr).inspect}" }
      "#<#{self.class} #{inspected_attributes.join(" ")}>"
    end

    def to_graphql_variables
      {
        "paymentContext" => {
          "amount" => amount&.to_graphql_variables,
          "cancelUrl" => cancel_url,
          "countryCode" => country_code,
          "expiryDate" => expiry_date,
          "merchantAccountId" => merchant_account_id,
          "orderId" => order_id,
          "payerInfo" => payer_info&.to_graphql_variables,
          "returnUrl" => return_url,
          "type" => type
        }.compact
      }
    end
  end
end
