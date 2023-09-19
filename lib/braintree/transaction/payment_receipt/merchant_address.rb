module Braintree
  class Transaction
    class PaymentReceipt
      class MerchantAddress
        include BaseModule

        attr_reader :locality
        attr_reader :phone
        attr_reader :postal_code
        attr_reader :region
        attr_reader :street_address

        def initialize(attributes)
          set_instance_variables_from_hash attributes unless attributes.nil?
        end
      end
    end
  end
end
