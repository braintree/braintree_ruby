module Braintree
  class AddOn < Modification

    # See http://www.braintreepayments.com/docs/ruby/add_ons/all
    def self.all
      Configuration.gateway.add_on.all
    end
  end
end
