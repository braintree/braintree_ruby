# 2.89.0
* Warn when instantiating a `Braintree::Gateway` with mixed environments
* Allow payee ID to be passed in options params for transaction create
* Add `merchant_id` to `ConnectedMerchantStatusTransitioned` and `ConnectedMerchantPayPalStatusChanged` Auth webhooks

# 2.88.0
* Add support for Micro Transfer ACH verifications
* Add `image_url` and `token` attributes to `AndroidPayDetails` and `ApplePayDetails`

# 2.87.0
* Add Dispute error ValidEvidenceRequiredToFinalize

# 2.86.0
* Remove `sepa_mandate_type` and `sepa_mandate_acceptance_location` params from `ClientTokenGateway`
* Add `payer_id` accessor in `PayPalAccount`
* Add support for VCR compelling evidence dispute representment

# 2.85.0
* Add support for `oauth_access_revocation` on `WebhookNotification`s
* Add support for US Bank Account verifications via `PaymentMethod#create`, `PaymentMethod#update`, and `Transaction#create`
* Add support for US Bank Account verification search

# 2.84.0
* Add support for `address.create!` to gateway instance
* Add support for `address.update!` to gateway instance
* Add support for `credit_card.create!` to gateway instance
* Add support for `customer.create!` to gateway instance
* Add support for `customer.update!` to gateway instance
* Add support for `document_upload.create!` to gateway instance
* Add support for `merchant_account.create!` to gateway instance
* Add support for `merchant_account.update!` to gateway instance
* Add support for `payment_method.create!` to gateway instance
* Add support for `payment_method.update!` to gateway instance
* Add support for `payment_method_nonce.create!` to gateway instance
* Add support for `subscription.cancel!` to gateway instance
* Add support for `subscription.create!` to gateway instance
* Add support for `subscription.update!` to gateway instance
* Add support for `subscription.retry_charge` to gateway instance
* Add support for `transaction.cancel_release!` to gateway instance
* Add support for `transaction.hold_in_escrow!` to gateway instance
* Add support for `transaction.clone_transction!` to gateway instance
* Add support for `transaction.credit!` to gateway instance
* Add support for `transaction.refund!` to gateway instance
* Add support for `transaction.release_from_escrow!` to gateway instance
* Add support for `transaction.sale!` to gateway instance
* Add support for `transaction.submit_for_settlement!` to gateway instance
* Add support for `transaction.submit_for_partial_settlement!` to gateway instance
* Add support for `transaction.void!` to gateway instance
* Add support for `profile_id` in Transaction#create options for VenmoAccounts
* Add support for `association_filter_id` in Customer#find
* Add support for `customer_id`, `disbursement_date` and `history_event_effective_date` in Dispute#search
* Update country names to have parity with documentation

# 2.83.0
* Add support for `tax_amount` field on transaction `line_items`
* Add support for `source_merchant_id` on webhooks
* Deprecated `DiscountAmountMustBeGreaterThanZero` error in favor of `DiscountAmountCannotBeNegative`.
* Deprecated `UnitTaxAmountMustBeGreaterThanZero` error in favor of `UnitTaxAmountCannotBeNegative`.
* Add `find_all` static method to `TransactionLineItem` class

# 2.82.0
* Add support for tagged evidence in DisputeGateway#add_text_evidence (Beta release)
* Update https certificate bundle

# 2.81.0
* Add support for line_items
* Update README to use instance methods

# 2.80.1
* Fix spec to expect PayPal transactions to move to settling rather than settled
* Fix permissions issue where SDK could not be loaded in some environments

# 2.80.0
* Add `bin_data` to Payment Method Nonce
* Add support for including level 3 summary fields to transaction create and transaction response

# 2.79.0
* Add `device_data_captured` field to `risk_data`
* Add submit_for_settlement to Braintree::Subscription.retry_charge
* Add `options` -> `paypal` -> `description` for creating and updating subscriptions
* Add `bin` to `ApplePayCard`
* Add support for upgrading a PayPal future payment refresh token to a billing agreement
* Fix spec to expect PayPal transaction to settle immediately after successful capture
* Add GrantedPaymentInstrumentUpdate webhook support
* Add `options` -> `paypal` -> `shipping` for creating & updating customers as well as creating payment methods
* Add ability to create a transaction from a shared nonce
* Add ruby 2.4 compatibility for the XML Generator (thanks @kinkade!)
* Add README note for supression of logs (thanks @badosu!)
* Allow `VenmoAccount` to be returned from `PaymentMethod.find` (thanks @NickMele!)

# 2.78.0
* Support `eci_indicator` for Transaction#sale with raw Apple Pay parameters

# 2.77.0
* Add `AuthorizationAdjustment` class and `authorization_adjustments` to Transaction
* Add document upload support
* Add Braintree::Dispute.find method
* Add Braintree::Dispute.search method
* Add Braintree::Dispute.accept method
* Add Braintree::Dispute.finalize method
* Add Braintree::Dispute.add_file_evidence method
* Add Braintree::Dispute.add_text_evidence method
* Add Braintree::Dispute.remove_evidence method
* Coinbase is no longer a supported payment method. `PaymentMethodNoLongerSupported` will be returned for Coinbase operations.
* Add Braintree::ApplePay for web domain registration
* Add facilitated details to Transaction if present

# 2.76.0
* Pass configured gateway to Merchant#_new instead of using global gateway (thanks @cwalsh!)

# 2.75.0
* Add support for additional PayPal options when vaulting a PayPal Order

# 2.74.0
* Add Visa Checkout support
* Add ConnectedMerchantStatusTransitioned and ConnectedMerchantPayPalStatusChanged Auth webhooks
* Add new properties to `CreditCardVerification` and `Customer`

# 2.73.0
* Bugfix: Add `unique_number_identifier` to Transaction::CreditCardDetails
* Updates to specs

# 2.72.0
* Remove `account_description` field from +UsBankAccount+ and +UsBankAccountDetails+

# 2.71.0
* Allow optional configuration of SSL version
* Add functionality to list all merchant accounts for a merchant with `merchant_account.all`

# 2.70.0
* Bugfix: Update UsBank tests to use legal routing numbers
* Add option +skip_advanced_fraud_check+ for transaction flows
* Add IdealPayment class with +sale+ and +find+ methods
* Add payer_status accessor to paypal_details object

# 2.69.1
* Bugfix: Allow PaymentMethod.find(token) to return +UsBankAccount+

# 2.69.0
* Add +default?+ support for +UsBankAccount+
* Add +ach_mandate+ data to +UsBankAccount+ and +UsBankAccountDetails+

# 2.68.2
* Bugfix: allow Customer#payment_methods to return UsBankAccounts

# 2.68.1
* Fix compatibility with new gateway endpoint

# 2.68.0
* Add 'UsBankAccount' payment method

# 2.67.0
* Add 'created_at' to subscription search
* Expose 'plan_id' in subscription 'status_details'
* Add cannot clone marketplace transaction error
* Add FailOnDuplicatePaymentMethod to Customer update

# 2.66.0
* Add 'currency_iso_code' to subscription 'status_details'
* Expose credit card 'product_id'
* Add validation error for verifications with submerchants

# 2.65.0
* Allow authenticated proxies
* Add new constant for Venmo Account payment instrument type

# 2.64.0
* Add 'default_payment_method' option to Customer

# 2.63.0
* Add order_id to Refund
* Enabled 3DS pass thru support
* Expose IDs in resource collections
* Add 'success?' method to disbursement

# 2.62.0
* Add method of revoking OAuth access tokens.

# 2.61.1
* Fix compatibility in specs with Ruby 1.8.7

# 2.61.0
* Add transaction +UpdateDetails+
* Support for Too Many Requests response codes
* Add +default?+ method to MerchantAccount

# 2.60.0
* Allow Coinbase account to be updated
* Add support to pass currencies to merchant create
* Support multiple partial settlements
* Add IsInvalid error code for addresses

# 2.59.0
* Add support for third party Android Pay integrations

# 2.58.0
* Add AccountUpdaterDailyReport webhook parsing

# 2.57.0
* Add Verification#create
* Add options to +submit_for_settlement+ transaction flows
* Upgrade libxml-ruby version to 2.8.0
* Update https certificate bundle

# 2.56.0
* Add better defaults to client token generation when using an access token by consolidating client token defaults into ClientTokenGateway
* Add PaymentMethod#revoke

# 2.55.0
* Add VenmoAccount
* Add support for Set Transaction Context supplementary data

# 2.54.0
* Treat dispute date_opened and date_won attributes as Dates. Note: in versions 2.51.0-2.53.0, the dispute date_opened and date_won attributes were incorrectly parsed as strings. We pulled them off RubyGems to prevent the incorrect code from being downloaded.

# 2.53.0
* This version of the library was removed from RubyGems. See the note on 2.54.0 for further explanation.
* Adds options to skip avs and cvv checks for a single transaction

# 2.52.0
* This version of the library was removed from RubyGems. See the note on 2.54.0 for further explanation.
* Add Amex Express Checkout payment method
* Fix bug where Customer#payment_methods didn't include Android Pay cards

# 2.51.0
* This version of the library was removed from RubyGems. See the note on 2.54.0 for further explanation.
* Fixes bug with signature of partner oauth connect url
* Adds date_won, date_opened and kind to dispute webhook parsing
* Make grant a method on PaymentMethod and not just CreditCard

# 2.50.0
* Adds support for nonce granting to CreditCards
* Adds FacilitatorDetails for facilitated transactions
* Adds authorized_transaction_id, partial_settlement_transaction_ids and facilitator_details attr_readers to Transaction
* Adds support for Transaction#sale with raw Apple Pay parameters
* Adds Merchant.provision_raw_apple_pay
* Relaxes constraints on TrasnactionSearch#source
* Adds Check WebhookNotifications
* Adds Transaction.submit_for_partial_settlement

# 2.49.0
* Remove Amex Pay with Points response from Transaction.sale response
* Add expired? method to Apple Pay card
* Add customer_id property to +AndroidPayCard+, +ApplePayCard+, +CoinbaseAccount+, +EuropeBankAccount+, +PaypalAccount+, and +UnknownPaymentMethod+
* Add new error +ProcessorDoesNotSupportAuths+

# 2.48.1
* Fix issue in TestTransaction spec
* Fix issue with LibXML causing a segfault when using Ruby version 2.0.0

# 2.48.0
* Add support for Amex rewards transactions
* Add billing_agreement_id to PayPalAccount
* Fix bug in TestingGateway#check_environment

# 2.47.0
* Add {ApplePayDetails,ApplePayCard,AndroidPayDetails,AndroidPayCard}#source_description
* Add AndroidPayDetails#source_card_type, #source_card_last_4
* Add PaypalDetails#description, #transaction_fee_amount, #transaction_fee_currency_iso_code
* Add new card-specific Android Pay test nonces
* Add various other test nonces

# 2.46.0
* Add oauth support

# 2.45.0
* Add support for Android Pay

# 2.44.0
* Validate webhook challenge payload
* Changed CreditCardVerification::Status constants
* Add missing criteria to CreditCardVerification search

# 2.43.0
* Add 3DS info to server side

# 2.42.0
* Add {ApplePayCard,CoinbaseAccount}#default?
* Add {ApplePayCard,CoinbaseAccount} payment instrument constants
* Add European Bank Account test nonce

# 2.41.0
* Add support for new SEPA workflow

# 2.40.0
* Add 3D Secure transaction fields
* Add ability to create nonce from vaulted payment methods

# 2.39.0
* Surface Apple Pay payment instrument name in responses
* Support Coinbase payment instruments
* Improve support for SEPA payment instruments
* Upgrade RSpec and improve tests
* Update links to documentation

# 2.38.0
* Use OpenSSL::Digest instead of OpenSSL::Digest::Digest (Thanks, Michael Koziarski (@NZKoz))

# 2.37.0
* Add risk_data to Transaction and Verification with Kount decision and id
* Add verification_amount an option when creating a credit card
* Add TravelCruise industry type to Transaction
* Add room_rate to Lodging industry type
* Add CreditCard#verification as the latest verification on that credit card
* Add ApplePay support to all endpoints that may return ApplePayCard objects
* Align WebhookTesting with other client libraries

# 2.36.0
* Allow descriptor to be passed in Funding Details options params for Merchant Account create and update.

# 2.35.0
* Add additional_processor_response to transaction

# 2.34.1
* Allow payee_email to be passed in options params for Transaction create

# 2.34.0
* Added paypal specific fields to transaction calls
* Added SettlementPending, SettlementDeclined transaction statuses

# 2.33.1
* Update version number

# 2.33.0
* Allow credit card verification options to be passed outside of the nonce for PaymentMethod.create
* Allow billing_address parameters and billing_address_id to be passed outside of the nonce for PaymentMethod.create
* Add Subscriptions to paypal accounts
* Add PaymentMethod.update
* Add fail_on_duplicate_payment_method option to PaymentMethod.create
* Add Descriptor#url

# 2.32.0
* Official support for v.zero SDKs.

# 2.31.0
* Add support for lodging industry data

# 2.30.2
* Ensure that TR Data is encoded correctly

# 2.30.1
* Make webhook parsing more robust with newlines
* Add messages to InvalidSignature exceptions

# 2.30.0
* Include Dispute information on Transaction
* Search for Transactions disputed on a certain date

# 2.29.0
* Disbursement Webhooks
* Use OpenSSL::Digest instead of OpenSSL::Digest::Digest (Thanks Scott Rocher, scottrocher@gmail.com)

# 2.28.0
* Merchant account find API

# 2.27.0
* Merchant account update API
* Merchant account create API v2

# 2.26.0
* Official support for Partnerships
* Changed visibility of methods used in multi-tenancy

# 2.25.0
* Adds hold_in_escrow and hold_in_escrow! methods
* Add error codes for verification not supported error
* Add company_name and tax_id to merchant account create
* Updates webhook notification to provide errors and merchant account at the top level
* Adds cancel_release and cancel_release! methods
* Refactors transaction_gateway
* Adds release_from_escrow!
* Adds release_from_escrow functionality
* Adds owner_phone to merchant account signature.
* Adds merchant account phone error code.

# 2.24.0
* Adds device data to transactions, customers, and credit cards.

# 2.23.0
* Adds disbursement details to transactions.
* Adds image_url to transactions.

# 2.22.0
* Adds channel field to transactions.

# 2.21.0
* Add card type indicators to transactions and verifications

# 2.20.0
* Add additional card types for card type indicators
* Added ability to allow TR query parameters with no value (thanks @dmathieu!)

# 2.19.0
* Adds verification search

# 2.18.0
* Additional card information, such as prepaid, debit, commercial, Durbin regulated, healthcare, and payroll, are returned on credit card responses
* Allows transactions to be specified as recurring

# 2.17.0
* Adds prepaid attribute to credit cards (possible values: Yes, No, Unknown)

# 2.16.0

* Adds webhook gateways for parsing, verifying, and testing incoming
notifications
* Adds Transaction.refund!(id, amount = nil)

# 2.15.0

* Adds unique_number_identifier attribute to CreditCard

# 2.14.0

* Adds search for duplicate credit cards given a payment method token
* Adds flag to fail saving credit card to vault if card is duplicate

# 2.13.4

* Allows both url encoded and decoded query string and hash

# 2.13.3

* Exposes plan_id on transactions
* Fixes GitHub issue #19 - Unescapes escaped characters in query string

# 2.13.2

* Added error code for invalid purchase order number
* Changes transparent redirect query string regexp to allow hash to appear
anywhere in params string

# 2.13.1

* Made the production endpoint configurable

# 2.13.0

* Added new error code for merchant accounts that do not support refunds
* Added GEMSPEC file

# 2.12.0

* Added ability to retrieve all Plans, AddOns and Discounts
* Added Transaction cloning

# 2.11.0

* Added SettlementBatchSummary

# 2.10.2

* Added support for international Maestro cards with payer authentication

# 2.10.1

* Support builder >= 2.0
* Changed comments to point to new doc site

# 2.10.0

* Added subscription_details to Transaction
* Added flag to store in vault only when a transaction is successful
* Added new error code

# 2.9.1

* Added a new transaction state, AuthorizationExpired.
* Enabled searching by authorization_expired_at.

# 2.8.0

* Added next_billing_date and transaction_id to subscription search
* Added address_country_name to customer search
* Added new error codes

# 2.7.0

* Added advanced vault search for customers and payment methods
* Added dynamic descriptors
* Added level 2 fields to transactions:
  * tax_amount
  * tax_exempt
  * purchase_order_number

# 2.6.3

* Allow passing of existing shipping_address_id on new transactions

# 2.6.2

* Added billing_address_id to allowed parameters for credit cards create and update
* Allow searching on subscriptions that are currently in a trial period using in_trial_period

# 2.6.1

* Now supports ruby 1.9.1 and 1.9.2

# 2.6.0

* Added ability to perform multiple partial refunds on Transactions
* Deprecated Transaction refund_id in favor of refund_ids
* Added Braintree::Address::CountryNames, a list of the country names/codes that the gateway accepts (thanks r38y[https://github.com/r38y])
* Added revert_subscription_on_proration_failure flag to Subscription update that specifies how a Subscription should react to a failed proration charge
* Deprecated Subscription next_bill_amount in favor of next_billing_period_amount
* Added new fields to Subscription:
  * balance
  * paid_through_date
  * next_billing_period_amount

# 2.5.2

* Removed ssl expiration check
* Lazy initialize Configuration.logger when directly instantiating configuration

# 2.5.1

* Lazy initialize Configuration.logger to fix bug with ssl expiration check

# 2.5.0

* Added AddOns/Discounts
* Enhanced Subscription search
* Enhanced Transaction search
* Made gateway operations threadsafe when using multiple configurations
* Allowed prorate_charges to be specified on Subscription update
* Added AddOn/Discount details to Transactions that were created from a Subscription
* Added Expired and Pending statuses to Subscription
* Added constants for CreditCardVerification statuses
* Renamed GatewayRejectionReason constants to make them more idiomatic
* Removed 13 digit Visa Sandbox Credit Card number and replaced it with a 16 digit Visa
* Added refund class method on Transaction
* Deprecated instance methods on Resource classes in favor of class methods
* Added new fields to Subscription:
  * billing_day_of_month
  * days_past_due
  * first_billing_date
  * never_expires
  * number_of_billing_cycles

# 2.4.0

* Added unified message to result objects
* Added ability to specify country using country_name, country_code_alpha2, country_code_alpha3, or country_code_numeric (see ISO_3166-1[https://en.wikipedia.org/wiki/ISO_3166-1])
* Added gateway_rejection_reason to Transaction and Verification
* Added delete as a class method on CreditCard (in addition to the existing instance method)
* Allow searching with Date objects (in addition to DateTime and Time objects)
* When creating a Subscription, return failed transaction on the ErrorResult if the initial transaction is not successful

# 2.3.1

* Fixed gem packaging

# 2.3.0

* Removed dependency on libxml -- it will still be used if libxml is explicitly required or it will fall back on rexml
* Added unified TransparentRedirect url and confirm methods and deprecated old methods
* Allow updating the payment_method_token on a subscription
* Added methods to link a Transaction with its refund and vice versa
* Allow card verification against a specified merchant account
* Added ability to update a customer, credit card, and billing address in one request

# 2.2.0

* Prevent race condition when pulling back collection results -- search results represent the state of the data at the time the query was run
* Rename ResourceCollection's approximate_size to maximum_size because items that no longer match the query will not be returned in the result set
* Correctly handle HTTP error 426 (Upgrade Required) -- the error code is returned when your client library version is no longer compatible with the gateway

# 2.1.0

* Added transaction advanced search
* Added ability to partially refund transactions
* Added ability to manually retry past-due subscriptions
* Added new transaction error codes
* Allow merchant account to be specified when creating transactions
* Allow creating a transaction with a vault customer and new payment method
* Allow existing billing address to be updated when updating credit card

# 2.0.0

* Updated success? on transaction responses to return false on declined transactions
* Search results now include Enumerable and will automatically paginate data
* Added credit_card[cardholder_name] to allowed transaction params and CreditCardDetails (thanks chrismcc[https://github.com/chrismcc])

# 1.2.1

* Added ValidationErrorCollection#shallow_errors to get all of the ValidationErrors at a given level in the error hierarchy
* Added the ability to make a credit card the default card for a customer
* Added constants for transaction statuses
* Updated Quick Start in README.rdoc to show a workflow with error checking

# 1.2.0

* Added Subscription search
* Updated production CA SSL certificate authority
* Updated credit cards to include associated subscriptions when finding in vault
* Fixed bug where we used to raise a "forged query string" exception when we were down for maintenance.

# 1.1.3

* Fixed a bug with empty search results
* Added support for appending to user agent
* Finding a customer using id as an integer will now work (even though customer ids are actually strings)

# 1.1.2

* Allow passing expiration_month and expiration_year separately
* Updated Customer.find to raise an ArgumentError if given an invalid id
* Added error code for transaction amounts that are too large
* Include Enumerable in Braintree::Errors to iterate over all validation errors
* Added processor_authorization_code attr_reader to Braintree::Transaction
* Added cvv_response_code attr_reader to Braintree::Transaction
* Added deep_errors method to Braintree::ValidationErrorCollection to get errors at every level of nesting

# 1.1.1

* Added explicit require for date to fix missing initialize (thanks jherdman[https://github.com/jherdman])
* Allow Transaction price and Subscription amount as BigDecimals (as well as Strings)
* Ruby 1.9 bug fixes (thanks Leo Shemesh)

# 1.1.0

* Recurring billing support

# 1.0.1

* Custom fields support
* Transaction status history support

# 1.0.0

* Initial release
