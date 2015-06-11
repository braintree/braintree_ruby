module Braintree
  class DiscountGateway # :nodoc
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def all
      response = @config.http.get("#{@config.base_merchant_path}/discounts")
      attributes_collection = response[:discounts]
      attributes_collection.map do |attributes|
        Discount._new(attributes)
      end
    end
  end
end
