module Braintree
  module Test # :nodoc:
    # The constants in this module can be used to create transactions with
    # the desired status in the sandbox environment.
    #
    # See http://www.braintreepayments.com/docs/ruby/reference/sandbox
    module TransactionAmounts
      Authorize = "1000.00"
      Decline = "2000.00"
      Fail = "3000.00"
    end
  end
end
