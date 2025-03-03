module Braintree
  module Test
    module CreditCardNumbers
      module CardTypeIndicators
        Prepaid           = "4111111111111210"
        PrepaidReloadable = "4229989900000002"
        Commercial        = "4111111111131010"
        Payroll           = "4111111114101010"
        Healthcare        = "4111111510101010"
        DurbinRegulated   = "4111161010101010"
        Debit             = "4117101010101010"
        Unknown           = "4111111111112101"
        No                = "4111111111310101"
        IssuingBank       = "4111111141010101"
        CountryOfIssuance = "4111111111121102"
      end

      AmExes = %w[378282246310005 371449635398431 378734493671000]
      CarteBlanches = %w[30569309025904]
      DinersClubs = %w[38520000023237]

      Discover = "6011111111111117"
      Discovers = %w[6011111111111117 6011000990139424]
      JCBs = %w[3530111333300000 3566002020360505]

      Maestro = "6304000000000000"
      MasterCard = "5555555555554444"
      MasterCardInternational = "5105105105105100"

      MasterCards = %w[5105105105105100 5555555555554444]

      Elo = "5066991111111118"
      Hiper = "6370950000000005"
      Hipercard = "6062820524845321"

      Visa = "4012888888881881"
      VisaCountryOfIssuanceIE = "4023490000000008"
      VisaInternational = "4009348888881881"
      VisaPrepaid = "4500600000000061"

      Fraud = "4000111111111511"
      RiskThreshold = "4111130000000003"

      Visas = %w[4009348888881881 4012888888881881 4111111111111111 4000111111111115 4500600000000061]
      Unknowns = %w[1000000000000008]

      module FailsSandboxVerification
        AmEx       = "378734493671000"
        Discover   = "6011000990139424"
        MasterCard = "5105105105105100"
        Visa       = "4000111111111115"
        Numbers    = [AmEx, Discover, MasterCard, Visa]
      end

      module AmexPayWithPoints
        Success            = "371260714673002"
        IneligibleCard     = "378267515471109"
        InsufficientPoints = "371544868764018"
        All = [Success, IneligibleCard, InsufficientPoints]
      end

      module Disputes
        Chargeback = "4023898493988028"

        Numbers = [Chargeback]
      end

      All = AmExes + Discovers + MasterCards + Visas + AmexPayWithPoints::All
    end

    module CreditCardDefaults
      CountryOfIssuance = "USA"
      IssuingBank = "NETWORK ONLY"
    end
  end
end
