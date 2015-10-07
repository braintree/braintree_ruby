module Braintree
  class Merchant
    include BaseModule # :nodoc:

    attr_reader :id, :email, :company_name, :country_code_alpha2, :country_code_alpha3, :country_code_numeric, :country_name

    def initialize(attributes) # :nodoc:
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
