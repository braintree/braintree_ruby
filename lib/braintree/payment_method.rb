module Braintree
  class PaymentMethod
    include BaseModule

    def self.create(attributes)
      Configuration.gateway.payment_method.create(attributes)
    end

    def self.find(token)
      Configuration.gateway.payment_method.find(token)
    end

    def self.update(token, attributes)
      Configuration.gateway.payment_method.update(token, attributes)
    end

    def self.delete(token, options = {})
      Configuration.gateway.payment_method.delete(token, options)
    end

    def self.grant(token, options = {})
      Configuration.gateway.payment_method.grant(token, options)
    end

    def self.revoke(token)
      Configuration.gateway.payment_method.revoke(token)
    end
  end
end
