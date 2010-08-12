module Braintree
  module Test # :nodoc:
    # The constants contained in the Braintree::Test::CreditCardNumbers module provide
    # credit card numbers that should be used when working in the sandbox environment. The sandbox
    # will not accept any credit card numbers other than the ones listed below.
    #
    # See http://www.braintreepaymentsolutions.com/docs/ruby/reference/sandbox
    module CreditCardNumbers
      AmExes = %w[
        378282246310005
        371449635398431
        378734493671000
      ]
      CarteBlanches = %w[30569309025904] # :nodoc:
      DinersClubs = %w[38520000023237] # :nodoc:

      Discovers = %w[
        6011111111111117
        6011000990139424
      ]
      JCBs = %w[3530111333300000 3566002020360505] # :nodoc:

      MasterCard = "5555555555554444"
      MasterCardInternational = "5105105105105100" # :nodoc:

      MasterCards = %w[5105105105105100 5555555555554444]

      Visa = "4012888888881881"
      VisaInternational = "4009348888881881" # :nodoc:

      Visas = %w[
        4009348888881881
        4012888888881881
        4111111111111111
        4000111111111115
      ]
      Unknowns = %w[
        1000000000000008
      ]

      module FailsSandboxVerification
        AmEx       = "378734493671000"
        Discover   = "6011000990139424"
        MasterCard = "5105105105105100"
        Visa       = "4000111111111115"
        Numbers    = [AmEx, Discover, MasterCard, Visa]
      end

      All = AmExes + Discovers + MasterCards + Visas
    end
  end
end
