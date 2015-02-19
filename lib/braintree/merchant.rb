module Braintree
  class Merchant
    include BaseModule

    def self.provision_raw_apple_pay
      Configuration.gateway.merchant.provision_raw_apple_pay
    end
  end
end
