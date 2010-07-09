module Braintree
  # The ErrorCodes module provides constants for validation errors.
  # The constants should be used to check for a specific validation error in a ValidationErrorCollection.
  # The error messages returned from the server may change, but the codes will remain the same.
  module ErrorCodes
    module Address
      CannotBeBlank = "81801"
      CompanyIsTooLong = "81802"
      CountryNameIsNotAccepted = "91803"
      CountryCodeAlpha2IsNotAccepted  = "91814"
      CountryCodeAlpha3IsNotAccepted  = "91816"
      CountryCodeNumericIsNotAccepted = "91817"
      ExtendedAddressIsTooLong = "81804"
      FirstNameIsTooLong = "81805"
      InconsistentCountry = "91815"
      LastNameIsTooLong = "81806"
      LocalityIsTooLong = "81807"
      PostalCodeInvalidCharacters = "81813"
      PostalCodeIsRequired = "81808"
      PostalCodeIsTooLong = "81809"
      RegionIsTooLong = "81810"
      StreetAddressIsRequired = "81811"
      StreetAddressIsTooLong = "81812"
    end

    module CreditCard
      BillingAddressConflict = "91701"
      BillingAddressIdIsInvalid = "91702"
      CardholderNameIsTooLong = "81723"
      CreditCardTypeIsNotAccepted = "81703"
      CreditCardTypeIsNotAcceptedBySubscriptionMerchantAccount = "81718"
      CustomerIdIsInvalid = "91705"
      CustomerIdIsRequired = "91704"
      CvvIsInvalid = "81707"
      CvvIsRequired = "81706"
      ExpirationDateConflict = "91708"
      ExpirationDateIsInvalid = "81710"
      ExpirationDateIsRequired = "81709"
      ExpirationDateYearIsInvalid = "81711"
      ExpirationMonthIsInvalid = "81712"
      ExpirationYearIsInvalid = "81713"
      NumberHasInvalidLength = "81716"
      NumberIsInvalid = "81715"
      NumberIsRequired = "81714"
      NumberMustBeTestNumber = "81717"
      TokenInvalid = "91718"
      TokenIsInUse = "91719"
      TokenIsNotAllowed = "91721"
      TokenIsRequired = "91722"
      TokenIsTooLong = "91720"

      module Options
        UpdateExistingTokenIsInvalid = "91723"
      end
    end

    module Customer
      CompanyIsTooLong = "81601"
      CustomFieldIsInvalid = "91602"
      CustomFieldIsTooLong = "81603"
      EmailIsInvalid = "81604"
      EmailIsRequired = "81606"
      EmailIsTooLong = "81605"
      FaxIsTooLong = "81607"
      FirstNameIsTooLong = "81608"
      IdIsInUse = "91609"
      IdIsInvaild = "91610"
      IdIsNotAllowed = "91611"
      IdIsRequired = "91613"
      IdIsTooLong = "91612"
      LastNameIsTooLong = "81613"
      PhoneIsTooLong = "81614"
      WebsiteIsInvalid = "81616"
      WebsiteIsTooLong = "81615"
    end

    module Subscription
      CannotEditCanceledSubscription = "81901"
      IdIsInUse =  "81902"
      MerchantAccountIdIsInvalid = "91901"
      PaymentMethodTokenCardTypeIsNotAccepted = "91902"
      PaymentMethodTokenIsInvalid = "91903"
      PaymentMethodTokenNotAssociatedWithCustomer = "91905"
      PlanIdIsInvalid = "91904"
      PriceCannotBeBlank = "81903"
      PriceFormatIsInvalid = "81904"
      StatusIsCanceled = "81905"
      TokenFormatIsInvalid = "81906"
      TrialDurationFormatIsInvalid =  "81907"
      TrialDurationIsRequired = "81908"
      TrialDurationUnitIsInvalid =  "81909"
    end

    module Transaction
      AmountCannotBeNegative = "81501"
      AmountIsRequired = "81502"
      AmountIsInvalid = "81503"
      AmountIsTooLarge = "81528"
      BillingAddressConflict = "91530"
      CannotBeVoided = "91504"
      CannotRefundCredit = "91505"
      CannotRefundUnlessSettled = "91506"
      CannotSubmitForSettlement = "91507"
      CreditCardIsRequired = "91508"
      CustomerDefaultPaymentMethodCardTypeIsNotAccepted = "81509"
      CustomFieldIsInvalid = "91526"
      CustomFieldIsTooLong = "81527"
      CustomerIdIsInvalid = "91510"
      CustomerDoesNotHaveCreditCard = "91511"
      HasAlreadyBeenRefunded = "91512"
      MerchantAccountNameIsInvalid = "91513"
      MerchantAccountIsSuspended = "91514"
      OrderIdIsTooLong = "91501"
      PaymentMethodConflict = "91515"
      PaymentMethodDoesNotBelongToCustomer = "91516"
      PaymentMethodDoesNotBelongToSubscription = "91527"
      PaymentMethodTokenCardTypeIsNotAccepted = "91517"
      PaymentMethodTokenIsInvalid = "91518"
      ProcessorAuthorizationCodeCannotBeSet = "91519"
      ProcessorAuthorizationCodeIsInvalid = "81520"
      RefundAmountIsTooLarge = "91521"
      SettlementAmountIsTooLarge = "91522"
      SubscriptionDoesNotBelongToCustomer = "91529"
      SubscriptionIdIsInvalid = "91528"
      TypeIsInvalid = "91523"
      TypeIsRequired = "91524"
      module Options
        VaultIsDisabled = "91525"
      end
    end
  end
end
