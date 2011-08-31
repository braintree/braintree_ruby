module Braintree
  class Discount < Modification

    # See http://www.braintreepayments.com/docs/ruby/discounts/all
    def self.all
      Configuration.gateway.discount.all
    end
  end
end
