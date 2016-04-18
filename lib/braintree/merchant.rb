module Braintree
  class Merchant
    include BaseModule # :nodoc:

    attr_reader :id, :email, :company_name, :country_code_alpha2, :country_code_alpha3, :country_code_numeric, :country_name, :merchant_accounts

    def initialize(attributes) # :nodoc:
      @merchant_accounts = attributes.delete(:merchant_accounts).map do |merchant_account|
        MerchantAccount._new(Configuration.gateway, merchant_account)
      end

      set_instance_variables_from_hash(attributes)
    end

    class << self
      protected :new
    end

    def self._new(*args) # :nodoc:
      self.new *args
    end

    def self.provision_raw_apple_pay
      Configuration.gateway.merchant.provision_raw_apple_pay
    end
  end
end
