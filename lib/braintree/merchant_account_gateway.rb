module Braintree
  class MerchantAccountGateway # :nodoc:
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def create(attributes)
      signature = MerchantAccountGateway._detect_signature(attributes)
      Util.verify_keys(signature, attributes)
      _do_create "/merchant_accounts/create_via_api", :merchant_account => attributes
    end

    def find(merchant_account_id)
      raise ArgumentError if merchant_account_id.nil? || merchant_account_id.to_s.strip == ""
      response = @config.http.get("#{@config.base_merchant_path}/merchant_accounts/#{merchant_account_id}")
      MerchantAccount._new(@gateway, response[:merchant_account])
    rescue NotFoundError
      raise NotFoundError, "Merchant account with id #{merchant_account_id} not found"
    end

    def update(merchant_account_id, attributes)
      Util.verify_keys(MerchantAccountGateway._update_signature, attributes)
      _do_update "/merchant_accounts/#{merchant_account_id}/update_via_api", :merchant_account => attributes
    end

    def _do_create(path, params=nil) # :nodoc:
      response = @config.http.post("#{@config.base_merchant_path}#{path}", params)
      if response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        SuccessfulResult.new(:merchant_account => MerchantAccount._new(@gateway, response[:merchant_account]))
      end
    end

    def _do_update(path, params=nil) # :nodoc:
      response = @config.http.put("#{@config.base_merchant_path}#{path}", params)
      if response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        SuccessfulResult.new(:merchant_account => MerchantAccount._new(@gateway, response[:merchant_account]))
      end
    end

    def self._detect_signature(attributes)
      if attributes.has_key?(:applicant_details)
        warn "[DEPRECATED] Passing :applicant_details to create is deprecated. Please use :individual, :business, and :funding."
        MerchantAccountGateway._deprecated_create_signature
      else
        MerchantAccountGateway._create_signature
      end
    end

    def self._deprecated_create_signature # :nodoc:
      [
        {:applicant_details => [
          :first_name, :last_name, :email, :date_of_birth, :ssn, :routing_number,
          :account_number, :tax_id, :company_name, :phone,
          {:address => [:street_address, :postal_code, :locality, :region]}]
        },
        :tos_accepted, :master_merchant_account_id, :id
      ]
    end

    def self._signature # :nodoc:
      [
        {:individual => [
          :first_name, :last_name, :email, :date_of_birth, :ssn, :phone,
          {:address => [:street_address, :locality, :region, :postal_code]}]
        },
        {:business => [
          :dba_name, :legal_name, :tax_id,
          {:address => [:street_address, :locality, :region, :postal_code]}]
        },
        {:funding => [:destination, :email, :mobile_phone, :routing_number, :account_number, :descriptor]}
      ]
    end

    def self._create_signature # :nodoc:
      _signature + [:tos_accepted, :master_merchant_account_id, :id]
    end

    def self._update_signature # :nodoc:
      _signature
    end
  end
end
