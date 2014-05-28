module Braintree
  # The ErrorCodes module provides constants for validation errors.
  # The constants should be used to check for a specific validation error in a ValidationErrorCollection.
  # The error messages returned from the server may change, but the codes will remain the same.
  module ErrorCodes
    # See http://www.braintreepayments.com/docs/ruby/addresses/validations
    module Address
      CompanyIsInvalid = "91821"
      CountryNameIsNotAccepted = "91803"
      CountryCodeAlpha2IsNotAccepted = "91814"
      CountryCodeAlpha3IsNotAccepted = "91816"
      CountryCodeNumericIsNotAccepted = "91817"
      CannotBeBlank = "81801"
      CompanyIsTooLong = "81802"
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
      CannotUpdateCardUsingPaymentMethodNonce = "91735"
      CustomerIdIsRequired = "91704"
      CustomerIdIsInvalid = "91705"
      ExpirationDateConflict = "91708"
      TokenFormatIsInvalid = "91718"
      TokenIsInUse = "91719"
      TokenIsTooLong = "91720"
      TokenIsNotAllowed = "91721"
      TokenIsRequired = "91722"
      CardholderNameIsTooLong = "81723"
      CreditCardTypeIsNotAccepted = "81703"
      CreditCardTypeIsNotAcceptedBySubscriptionMerchantAccount = "81718"
      CvvIsRequired = "81706"
      CvvIsInvalid = "81707"
      DuplicateCardExists = "81724"
      ExpirationDateIsRequired = "81709"
      ExpirationDateIsInvalid = "81710"
      ExpirationDateYearIsInvalid = "81711"
      ExpirationMonthIsInvalid = "81712"
      ExpirationYearIsInvalid = "81713"
      InvalidVenmoSDKPaymentMethodCode = "91727"
      NumberIsRequired = "81714"
      NumberIsInvalid = "81715"
      NumberLengthIsInvalid = "81716"
      NumberMustBeTestNumber = "81717"
      PaymentMethodConflict = "81725"
      PaymentMethodNonceCardTypeIsNotAccepted = "91734"
      PaymentMethodNonceConsumed = "91731"
      PaymentMethodNonceLocked = "91733"
      PaymentMethodNonceUnknown = "91732"
      VenmoSDKPaymentMethodCodeCardTypeIsNotAccepted = "91726"
      VerificationNotSupportedOnThisMerchantAccount = "91730"

      module Options
        UpdateExistingTokenIsInvalid = "91723"
        VerificationMerchantAccountIdIsInvalid = "91728"
        UpdateExistingTokenNotAllowed = "91729"
      end
    end

    # See http://www.braintreepayments.com/docs/ruby/customers/validations
    module Customer
      CustomFieldIsInvalid = "91602"
      IdIsInUse = "91609"
      IdIsInvalid = "91610"
      IdIsNotAllowed = "91611"
      IdIsRequired = "91613"
      IdIsTooLong = "91612"
      CompanyIsTooLong = "81601"
      CustomFieldIsTooLong = "81603"
      EmailFormatIsInvalid = "81604"
      EmailIsTooLong = "81605"
      EmailIsRequired = "81606"
      FaxIsTooLong = "81607"
      FirstNameIsTooLong = "81608"
      LastNameIsTooLong = "81613"
      PhoneIsTooLong = "81614"
      WebsiteIsTooLong = "81615"
      WebsiteFormatIsInvalid = "81616"
    end

    module Descriptor
      NameFormatIsInvalid = "92201"
      PhoneFormatIsInvalid = "92202"
      DynamicDescriptorsDisabled = "92203"
      InternationalNameFormatIsInvalid = "92204"
      InternationalPhoneFormatIsInvalid = "92205"
    end

    module PayPalAccount
      CannotVaultOneTimeUsePayPalAccount = "82902"
      CannotHaveBothAccessTokenAndConsentCode = "82903"
      ConsentCodeOrAccessTokenIsRequired = "82901"
      CustomerIdIsRequiredForVaulting = "82905"
      PaymentMethodNonceConsumed = "92907"
      PaymentMethodNonceLocked = "92909"
      PaymentMethodNonceUnknown = "92908"
      PayPalAccountsAreNotAccepted = "82904"
      PayPalCommunicationError = "92910"
      TokenIsInUse = "92906"
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
      AmountFormatIsInvalid = "81503" # Keep for backwards compatibility
      AmountIsInvalid = "81503" # Keep for backwards compatibility
      AmountIsRequired = "81502"
      AmountIsTooLarge = "81528"
      AmountMustBeGreaterThanZero = "81531"
      BillingAddressConflict = "91530"
      CannotBeVoided = "91504"
      CannotCancelRelease = "91562"
      CannotCloneCredit = "91543"
      CannotCloneTransactionWithVaultCreditCard = "91540"
      CannotCloneUnsuccessfulTransaction = "91542"
      CannotCloneVoiceAuthorizations = "91541"
      CannotHoldInEscrow = "91560"
      CannotPartiallyRefundEscrowedTransaction = "91563"
      CannotRefundCredit = "91505"
      CannotRefundUnlessSettled = "91506"
      CannotRefundWithPendingMerchantAccount = "91559"
      CannotRefundWithSuspendedMerchantAccount = "91538"
      CannotReleaseFromEscrow = "91561"
      CannotSubmitForSettlement = "91507"
      CreditCardIsRequired = "91508"
      CustomFieldIsInvalid = "91526"
      CustomFieldIsTooLong = "81527"
      CustomerDefaultPaymentMethodCardTypeIsNotAccepted = "81509"
      CustomerDoesNotHaveCreditCard = "91511"
      CustomerIdIsInvalid = "91510"
      HasAlreadyBeenRefunded = "91512"
      MerchantAccountDoesNotSupportRefunds = "91547"
      MerchantAccountDoesNotSupportMOTO = "91558"
      MerchantAccountIdIsInvalid = "91513"
      MerchantAccountIsSuspended = "91514"
      OrderIdIsTooLong = "91501"
      ChannelIsTooLong = "91550"
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
      PurchaseOrderNumberIsInvalid = "91548"
      PurchaseOrderNumberIsTooLong = "91537"
      RefundAmountIsTooLarge = "91521"
      ServiceFeeAmountCannotBeNegative = "91554"
      ServiceFeeAmountFormatIsInvalid = "91555"
      ServiceFeeAmountIsTooLarge = "91556"
      ServiceFeeIsNotAllowedOnCredits = "91552"
      ServiceFeeAmountNotAllowedOnMasterMerchantAccount = "91557"
      SettlementAmountIsLessThanServiceFeeAmount = "91551"
      SettlementAmountIsTooLarge = "91522"
      SubMerchantAccountRequiresServiceFeeAmount = "91553"
      SubscriptionDoesNotBelongToCustomer = "91529"
      SubscriptionIdIsInvalid = "91528"
      SubscriptionStatusMustBePastDue = "91531"
      TaxAmountCannotBeNegative = "81534"
      TaxAmountFormatIsInvalid = "81535"
      TaxAmountIsTooLarge = "81536"
      ThreeDSecureTokenIsInvalid = "91568"
      ThreeDSecureTransactionDataDoesntMatchVerify = "91570"
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
      TosAcceptedIsRequired = "82610"
      IdCannotBeUpdated = "82675"
      MasterMerchantAccountIdCannotBeUpdated = "82676"
      CannotBeUpdated = "82674"
      DeclinedOFAC = "82621"
      DeclinedMasterCardMatch = "82622"
      DeclinedFailedKYC = "82623"
      DeclinedSsnInvalid = "82624"
      DeclinedSsnMatchesDeceased = "82625"
      Declined = "82626"

      module ApplicantDetails
        FirstNameIsRequired = "82609"
        LastNameIsRequired = "82611"
        DateOfBirthIsRequired = "82612"
        RoutingNumberIsRequired = "82613"
        AccountNumberIsRequired = "82614"
        SsnIsInvalid = "82615"
        EmailAddressIsInvalid = "82616"
        FirstNameIsInvalid = "82627"
        LastNameIsInvalid = "82628"
        CompanyNameIsInvalid = "82631"
        TaxIdIsInvalid = "82632"
        CompanyNameIsRequiredWithTaxId = "82633"
        TaxIdIsRequiredWithCompanyName = "82634"
        RoutingNumberIsInvalid = "82635"
        DeclinedOFAC = "82621"               # Keep for backwards compatibility
        DeclinedMasterCardMatch = "82622"    # Keep for backwards compatibility
        DeclinedFailedKYC = "82623"          # Keep for backwards compatibility
        DeclinedSsnInvalid = "82624"         # Keep for backwards compatibility
        DeclinedSsnMatchesDeceased = "82625" # Keep for backwards compatibility
        Declined = "82626"                   # Keep for backwards compatibility
        PhoneIsInvalid = "82636"
        DateOfBirthIsInvalid = "82663"
        AccountNumberIsInvalid = "82670"
        EmailAddressIsRequired = "82665"
        TaxIdMustBeBlank = "82673"

        module Address
          StreetAddressIsRequired = "82617"
          LocalityIsRequired = "82618"
          PostalCodeIsRequired = "82619"
          RegionIsRequired = "82620"
          StreetAddressIsInvalid = "82629"
          PostalCodeIsInvalid = "82630"
          RegionIsInvalid = "82664"
        end
      end

      module Individual
        FirstNameIsRequired = "82637"
        LastNameIsRequired = "82638"
        DateOfBirthIsRequired = "82639"
        SsnIsInvalid = "82642"
        EmailIsInvalid = "82643"
        FirstNameIsInvalid = "82644"
        LastNameIsInvalid = "82645"
        PhoneIsInvalid = "82656"
        DateOfBirthIsInvalid = "82666"
        EmailIsRequired = "82667"

        module Address
          StreetAddressIsRequired = "82657"
          LocalityIsRequired = "82658"
          PostalCodeIsRequired = "82659"
          RegionIsRequired = "82660"
          StreetAddressIsInvalid = "82661"
          PostalCodeIsInvalid = "82662"
          RegionIsInvalid = "82668"
        end
      end

      module Business
        DbaNameIsInvalid = "82646"
        LegalNameIsInvalid = "82677"
        LegalNameIsRequiredWithTaxId = "82669"
        TaxIdIsInvalid = "82647"
        TaxIdIsRequiredWithLegalName = "82648"
        TaxIdMustBeBlank = "82672"
        module Address
          StreetAddressIsInvalid = "82685"
          PostalCodeIsInvalid = "82686"
          RegionIsInvalid = "82684"
        end
      end

      module Funding
        AccountNumberIsInvalid = "82671"
        AccountNumberIsRequired = "82641"
        DestinationIsInvalid = "82679"
        DestinationIsRequired = "82678"
        EmailIsInvalid = "82681"
        EmailIsRequired = "82680"
        MobilePhoneIsInvalid = "82683"
        MobilePhoneIsRequired = "82682"
        RoutingNumberIsInvalid = "82649"
        RoutingNumberIsRequired = "82640"
      end
    end

    module SettlementBatchSummary
      SettlementDateIsRequired = "82301"
      SettlementDateIsInvalid = "82302"
      CustomFieldIsInvalid = "82303"
    end
  end
end

