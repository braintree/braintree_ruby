module Braintree
  # The ErrorCodes module provides constants for validation errors.
  # The constants should be used to check for a specific validation error in a ValidationErrorCollection.
  # The error messages returned from the server may change, but the codes will remain the same.
  module ErrorCodes
    # See http://www.braintreepayments.com/docs/ruby/addresses/validations
    module Address
      CannotBeBlank = "81801"
      CompanyIsInvalid = "91821"
      CompanyIsTooLong = "81802"
      CountryCodeAlpha2IsNotAccepted  = "91814"
      CountryCodeAlpha3IsNotAccepted  = "91816"
      CountryCodeNumericIsNotAccepted = "91817"
      CountryNameIsNotAccepted = "91803"
      ExtendedAddressIsInvalid = "91823"
      ExtendedAddressIsTooLong = "81804"
      FirstNameIsInvalid = "91819"
      FirstNameIsTooLong = "81805"
      InconsistentCountry = "91815"
      LastNameIsInvalid = "91820"
      LastNameIsTooLong = "81806"
      LocalityIsInvalid = "91824"
      LocalityIsTooLong = "81807"
      PostalCodeInvalidCharacters = "81813"
      PostalCodeIsInvalid = "91826"
      PostalCodeIsRequired = "81808"
      PostalCodeIsTooLong = "81809"
      RegionIsInvalid = "91825"
      RegionIsTooLong = "81810"
      StreetAddressIsInvalid = "91822"
      StreetAddressIsRequired = "81811"
      StreetAddressIsTooLong = "81812"
      TooManyAddressesPerCustomer = "91818"
    end

    # See http://www.braintreepayments.com/docs/ruby/credit_cards/validations
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
      DuplicateCardExists = "81724"
      ExpirationDateConflict = "91708"
      ExpirationDateIsInvalid = "81710"
      ExpirationDateIsRequired = "81709"
      ExpirationDateYearIsInvalid = "81711"
      ExpirationMonthIsInvalid = "81712"
      ExpirationYearIsInvalid = "81713"
      InvalidVenmoSDKPaymentMethodCode = "91727"
      NumberHasInvalidLength = "81716"
      NumberLengthIsInvalid = "81716"
      NumberIsInvalid = "81715"
      NumberIsRequired = "81714"
      NumberMustBeTestNumber = "81717"
      PaymentMethodConflict = "81725"
      TokenInvalid = "91718"
      TokenFormatIsInvalid = "91718"
      TokenIsInUse = "91719"
      TokenIsNotAllowed = "91721"
      TokenIsRequired = "91722"
      TokenIsTooLong = "91720"
      VenmoSDKPaymentMethodCodeCardTypeIsNotAccepted = "91726"

      module Options
        UpdateExistingTokenIsInvalid = "91723"
        VerificationMerchantAccountIdIsInvalid = "91728"
      end
    end

    # See http://www.braintreepayments.com/docs/ruby/customers/validations
    module Customer
      CompanyIsTooLong = "81601"
      CustomFieldIsInvalid = "91602"
      CustomFieldIsTooLong = "81603"
      EmailIsInvalid = "81604"
      EmailFormatIsInvalid = "81604"
      EmailIsRequired = "81606"
      EmailIsTooLong = "81605"
      FaxIsTooLong = "81607"
      FirstNameIsTooLong = "81608"
      IdIsInUse = "91609"
      IdIsInvaild = "91610" # Deprecated
      IdIsInvalid = "91610"
      IdIsNotAllowed = "91611"
      IdIsRequired = "91613"
      IdIsTooLong = "91612"
      LastNameIsTooLong = "81613"
      PhoneIsTooLong = "81614"
      WebsiteIsInvalid = "81616"
      WebsiteFormatIsInvalid = "81616"
      WebsiteIsTooLong = "81615"
    end

    module Descriptor
      DynamicDescriptorsDisabled = "92203"
      InternationalPhoneFormatIsInvalid = "92205"
      InternationalNameFormatIsInvalid = "92204"
      NameFormatIsInvalid = "92201"
      PhoneFormatIsInvalid = "92202"
    end

    module SettlementBatchSummary
      CustomFieldIsInvalid = "82303"
      SettlementDateIsInvalid = "82302"
      SettlementDateIsRequired = "82301"
    end

    # See http://www.braintreepayments.com/docs/ruby/subscriptions/validations
    module Subscription
      BillingDayOfMonthCannotBeUpdated = "91918"
      BillingDayOfMonthIsInvalid = "91914"
      BillingDayOfMonthMustBeNumeric = "91913"
      CannotAddDuplicateAddonOrDiscount = "91911"
      CannotEditCanceledSubscription = "81901"
      CannotEditExpiredSubscription = "81910"
      CannotEditPriceChangingFieldsOnPastDueSubscription = "91920"
      FirstBillingDateCannotBeInThePast = "91916"
      FirstBillingDateCannotBeUpdated = "91919"
      FirstBillingDateIsInvalid = "91915"
      IdIsInUse = "81902"
      InconsistentNumberOfBillingCycles = "91908"
      InconsistentStartDate = "91917"
      InvalidRequestFormat = "91921"
      MerchantAccountIdIsInvalid = "91901"
      MismatchCurrencyISOCode = "91923"
      NumberOfBillingCyclesCannotBeBlank = "91912"
      NumberOfBillingCyclesIsTooSmall = "91909"
      NumberOfBillingCyclesMustBeGreaterThanZero = "91907"
      NumberOfBillingCyclesMustBeNumeric = "91906"
      PaymentMethodTokenCardTypeIsNotAccepted = "91902"
      PaymentMethodTokenIsInvalid = "91903"
      PaymentMethodTokenNotAssociatedWithCustomer = "91905"
      PlanBillingFrequencyCannotBeUpdated = "91922"
      PlanIdIsInvalid = "91904"
      PriceCannotBeBlank = "81903"
      PriceFormatIsInvalid = "81904"
      PriceIsTooLarge = "81923"
      StatusIsCanceled = "81905"
      TokenFormatIsInvalid = "81906"
      TrialDurationFormatIsInvalid = "81907"
      TrialDurationIsRequired = "81908"
      TrialDurationUnitIsInvalid = "81909"

      module Modification
        AmountCannotBeBlank = "92003"
        AmountIsInvalid = "92002"
        AmountIsTooLarge = "92023"
        CannotEditModificationsOnPastDueSubscription = "92022"
        CannotUpdateAndRemove = "92015"
        ExistingIdIsIncorrectKind = "92020"
        ExistingIdIsInvalid = "92011"
        ExistingIdIsRequired = "92012"
        IdToRemoveIsIncorrectKind = "92021"
        IdToRemoveIsNotPresent = "92016"
        InconsistentNumberOfBillingCycles = "92018"
        InheritedFromIdIsInvalid = "92013"
        InheritedFromIdIsRequired = "92014"
        Missing = "92024"
        NumberOfBillingCyclesCannotBeBlank = "92017"
        NumberOfBillingCyclesIsInvalid = "92005"
        NumberOfBillingCyclesMustBeGreaterThanZero = "92019"
        QuantityCannotBeBlank = "92004"
        QuantityIsInvalid = "92001"
        QuantityMustBeGreaterThanZero = "92010"
      end
    end

    # See http://www.braintreepayments.com/docs/ruby/transactions/validations
    module Transaction
      AmountCannotBeNegative = "81501"
      AmountIsInvalid = "81503"
      AmountFormatIsInvalid = "81503"
      AmountIsRequired = "81502"
      AmountIsTooLarge = "81528"
      AmountMustBeGreaterThanZero = "81531"
      BillingAddressConflict = "91530"
      CannotBeVoided = "91504"
      CannotCloneCredit = "91543"
      CannotCloneTransactionWithVaultCreditCard = "91540"
      CannotCloneUnsuccessfulTransaction = "91542"
      CannotCloneVoiceAuthorizations = "91541"
      CannotRefundCredit = "91505"
      CannotRefundUnlessSettled = "91506"
      CannotRefundWithSuspendedMerchantAccount = "91538"
      CannotSubmitForSettlement = "91507"
      ChannelIsTooLong = "91550"
      CreditCardIsRequired = "91508"
      CustomFieldIsInvalid = "91526"
      CustomFieldIsTooLong = "81527"
      CustomerDefaultPaymentMethodCardTypeIsNotAccepted = "81509"
      CustomerDoesNotHaveCreditCard = "91511"
      CustomerIdIsInvalid = "91510"
      HasAlreadyBeenRefunded = "91512"
      MerchantAccountIdIsInvalid = "91513"
      MerchantAccountIsSuspended = "91514"
      MerchantAccountDoesNotSupportRefunds = "91547"
      MerchantAccountNameIsInvalid = "91513" # Deprecated
      OrderIdIsTooLong = "91501"
      PaymentMethodConflict = "91515"
      PaymentMethodConflictWithVenmoSDK = "91549"
      PaymentMethodDoesNotBelongToCustomer = "91516"
      PaymentMethodDoesNotBelongToSubscription = "91527"
      PaymentMethodTokenCardTypeIsNotAccepted = "91517"
      PaymentMethodTokenIsInvalid = "91518"
      ProcessorAuthorizationCodeCannotBeSet = "91519"
      ProcessorAuthorizationCodeIsInvalid = "81520"
      ProcessorDoesNotSupportCredits = "91546"
      ProcessorDoesNotSupportVoiceAuthorizations = "91545"
      PurchaseOrderNumberIsTooLong = "91537"
      PurchaseOrderNumberIsInvalid = "91548"
      RefundAmountIsTooLarge = "91521"
      SettlementAmountIsTooLarge = "91522"
      SubscriptionDoesNotBelongToCustomer = "91529"
      SubscriptionIdIsInvalid = "91528"
      SubscriptionStatusMustBePastDue = "91531"
      TaxAmountCannotBeNegative = "81534"
      TaxAmountFormatIsInvalid = "81535"
      TaxAmountIsTooLarge = "81536"
      TypeIsInvalid = "91523"
      TypeIsRequired = "91524"
      UnsupportedVoiceAuthorization = "91539"

      module Options
        SubmitForSettlementIsRequiredForCloning = "91544"
        VaultIsDisabled = "91525"
      end
    end

    module MerchantAccount
      IdIsTooLong = "82602"
      IdFormatIsInvalid = "82603"
      IdIsInUse = "82604"
      IdIsNotAllowed = "82605"
      MasterMerchantAccountIdIsRequired = "82606"
      MasterMerchantAccountIdIsInvalid = "82607"
      MasterMerchantAccountMustBeActive = "82608"

      module ApplicantDetails
        FirstNameIsRequired = "82609"
      end
    end
  end
end
