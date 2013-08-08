module Braintree
  class MerchantAccountGateway # :nodoc:
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def create(attributes)
      Util.verify_keys(MerchantAccountGateway._create_signature, attributes)
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

    def self._create_signature # :nodoc:
      [
        {:applicant_details => [
          :first_name, :last_name, :email, :date_of_birth, :ssn, :routing_number,
          :account_number, :tax_id, :company_name, :phone,
          {:address => [:street_address, :postal_code, :locality, :region]}]
        },
        :tos_accepted, :master_merchant_account_id, :id
      ]
    end
  end
end
