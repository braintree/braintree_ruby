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
      if response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        SuccessfulResult.new(:merchant_account => MerchantAccount._new(@gateway, response[:merchant_account]))
      end
    end
  end
end
