module Braintree
  module ThreeDSecurePassThru
    module Network
      Eftpos = "eftpos"
      MasterCard = "Mastercard"
      Visa = "Visa"

      All = constants.map { |c| const_get(c) }
    end
  end
end
