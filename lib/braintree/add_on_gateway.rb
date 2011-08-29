module Braintree
  class AddOnGateway # :nodoc
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def all
      response = @config.http.get "/add_ons"
      attributes_collection = response[:add_ons]
      attributes_collection.map do |attributes|
        AddOn._new(attributes)
      end
    end
  end
end
