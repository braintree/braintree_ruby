module Braintree
  class DiscountGateway # :nodoc
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def all
      response = @config.http.get "/discounts"
      attributes_collection = response[:modifications]
      attributes_collection.map do |attributes|
        Discount._new(attributes)
      end
    end
  end
end
