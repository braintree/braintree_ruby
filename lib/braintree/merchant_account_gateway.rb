module Braintree
  class MerchantAccountGateway # :nodoc:
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def create(attributes)
      _do_create "/merchant_accounts/create_via_api", :merchant_account => attributes
    end

    def _do_create(url, params=nil) # :nodoc:
      response = @config.http.post url, params
      SuccessfulResult.new(:merchant_account => MerchantAccount._new(@gateway, response[:merchant_account]))
    end
  end
end
