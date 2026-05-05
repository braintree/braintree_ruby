module Braintree
  class LocalPaymentContext
    include BaseModule

    attr_reader :amount
    attr_reader :approval_url
    attr_reader :approved_at
    attr_reader :attrs
    attr_reader :created_at
    attr_reader :expired_at
    attr_reader :id
    attr_reader :legacy_id
    attr_reader :merchant_account_id
    attr_reader :order_id
    attr_reader :payment_id
    attr_reader :transacted_at
    attr_reader :type
    attr_reader :updated_at

    def initialize(attributes)
      @attrs = [:amount, :approval_url, :approved_at, :attrs, :created_at, :expired_at, :id, :legacy_id,
                :merchant_account_id, :order_id, :payment_id, :transacted_at, :type, :updated_at]

      if attributes.key?(:response)
        response = attributes[:response]
        @id = _get_value(response, "paymentContext.id")
        @legacy_id = _get_value_optional(response, "paymentContext.legacyId")
        @type = _get_value(response, "paymentContext.type")
        @payment_id = _get_value_optional(response, "paymentContext.paymentId")
        @order_id = _get_value_optional(response, "paymentContext.orderId")
        @approval_url = _get_value_optional(response, "paymentContext.approvalUrl")
        @merchant_account_id = _get_value_optional(response, "paymentContext.merchantAccountId")
        @created_at = _get_value_optional(response, "paymentContext.createdAt")
        @updated_at = _get_value_optional(response, "paymentContext.updatedAt")
        @transacted_at = _get_value_optional(response, "paymentContext.transactedAt")
        @approved_at = _get_value_optional(response, "paymentContext.approvedAt")
        @expired_at = _get_value_optional(response, "paymentContext.expiredAt")
        @amount = _extract_amount(response)
      else
        set_instance_variables_from_hash(attributes)
      end
    end

    def inspect
      inspected_attributes = @attrs.map { |attr| "#{attr}:#{send(attr).inspect}" }
      "#<#{self.class} #{inspected_attributes.join(" ")}>"
    end

    class << self
      protected :new
    end

    def self._new(*args)
      self.new(*args)
    end

    private

    def _extract_amount(response)
      amount_hash = _get_value_optional(response, "paymentContext.amount")
      return nil unless amount_hash

      currency = amount_hash[:currencyCode] || amount_hash["currencyCode"] ||
                 amount_hash[:currencyIsoCode] || amount_hash["currencyIsoCode"]

      MonetaryAmount._new({
        value: amount_hash[:value] || amount_hash["value"],
        currency_code: currency
      })
    end

    def _get_value(response, key)
      current_map = response
      key_parts = key.split(".")

      (0...key_parts.length - 1).each do |i|
        sub_key = key_parts[i]
        current_map = _pop_value(current_map, sub_key)
      end

      last_key = key_parts[-1]
      _pop_value(current_map, last_key)
    end

    def _get_value_optional(response, key)
      _get_value(response, key)
    rescue ServerError
      nil
    end

    def _pop_value(response, key)
      if response.key?(key)
        return response[key]
      end

      symkey = key.to_sym
      if response.key?(symkey)
        return response[symkey]
      end

      if response.key?(key.to_s)
        return response[key.to_s]
      end

      raise ServerError.new("Couldn't parse response")
    end
  end
end
