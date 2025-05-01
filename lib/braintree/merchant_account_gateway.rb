module Braintree
  class MerchantAccountGateway
    include BaseModule

    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
      @config.assert_has_access_token_or_keys
    end

    def all
      pc = PaginatedCollection.new { |page| _fetch_merchant_accounts(page) }
      SuccessfulResult.new(:merchant_accounts => pc)
    end

    def _fetch_merchant_accounts(page_number)
      response = @config.http.get("#{@config.base_merchant_path}/merchant_accounts?page=#{page_number}")
      body = response[:merchant_accounts]
      merchant_accounts = Util.extract_attribute_as_array(body, :merchant_account).map { |merchant_account| MerchantAccount._new(@gateway, merchant_account) }
      PaginatedResult.new(body[:total_items], body[:page_size], merchant_accounts)
    end

    def find(merchant_account_id)
      raise ArgumentError if merchant_account_id.nil? || merchant_account_id.to_s.strip == ""
      response = @config.http.get("#{@config.base_merchant_path}/merchant_accounts/#{merchant_account_id}")
      MerchantAccount._new(@gateway, response[:merchant_account])
    rescue NotFoundError
      raise NotFoundError, "Merchant account with id #{merchant_account_id} not found"
    end

    def create_for_currency(params)
      _create_for_currency(params)
    end

    def _create_for_currency(params)
      response = @config.http.post("#{@config.base_merchant_path}/merchant_accounts/create_for_currency", :merchant_account => params)

      if response.has_key?(:response) && response[:response][:merchant_account]
        Braintree::SuccessfulResult.new(
          :merchant_account => MerchantAccount._new(@gateway, response[:response][:merchant_account]),
        )
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :merchant or :api_error_response"
      end
    end
  end
end
