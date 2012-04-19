module Braintree
  class PlanGateway # :nodoc:
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def all
      response = @config.http.get "/plans"
      attributes_collection = response[:plans] || []
      attributes_collection.map do |attributes|
        Plan._new(@gateway, attributes)
      end
    end
  end
end
