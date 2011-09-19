$:.unshift File.expand_path(File.dirname(__FILE__))

require "bigdecimal"
require "cgi"
require "date"
require "digest/sha1"
require "enumerator"
require "forwardable"
require "logger"
require "net/http"
require "net/https"
require "openssl"
require "stringio"
require "time"
require "zlib"

require "builder"

module Braintree
  autoload :BaseModule,                    'braintree/base_module'
  autoload :Modification,                  'braintree/modification'
  autoload :AddOn,                         'braintree/add_on'
  autoload :AddOnGateway,                  'braintree/add_on_gateway'
  autoload :Address,                       'braintree/address'
  autoload :AddressGateway,                'braintree/address_gateway'
  autoload :AdvancedSearch,                'braintree/advanced_search'
  autoload :Configuration,                 'braintree/configuration'
  autoload :CreditCard,                    'braintree/credit_card'
  autoload :CreditCardGateway,             'braintree/credit_card_gateway'
  autoload :CreditCardVerification,        'braintree/credit_card_verification'
  autoload :Customer,                      'braintree/customer'
  autoload :CustomerGateway,               'braintree/customer_gateway'
  autoload :CustomerSearch,                'braintree/customer_search'
  autoload :Descriptor,                    'braintree/descriptor'
  autoload :Digest,                        'braintree/digest'
  autoload :Discount,                      'braintree/discount'
  autoload :DiscountGateway,               'braintree/discount_gateway'
  autoload :ErrorCodes,                    'braintree/error_codes'
  autoload :ErrorResult,                   'braintree/error_result'
  autoload :Errors,                        'braintree/errors'
  autoload :Gateway,                       'braintree/gateway'
  autoload :Http,                          'braintree/http'
  autoload :Plan,                          'braintree/plan'
  autoload :PlanGateway,                   'braintree/plan_gateway'
  autoload :SettlementBatchSummary,        'braintree/settlement_batch_summary'
  autoload :SettlementBatchSummaryGateway, 'braintree/settlement_batch_summary_gateway'
  autoload :ResourceCollection,            'braintree/resource_collection'
  autoload :Subscription,                  'braintree/subscription'
  autoload :SubscriptionGateway,           'braintree/subscription_gateway'
  autoload :SubscriptionSearch,            'braintree/subscription_search'
  autoload :SuccessfulResult,              'braintree/successful_result'

  module Test
    autoload :CreditCardNumbers,           'braintree/test/credit_card_numbers'
    autoload :TransactionAmounts,          'braintree/test/transaction_amounts'
  end

  autoload :Transaction,                   'braintree/transaction'
  autoload :TransactionGateway,            'braintree/transaction_gateway'
  autoload :TransactionSearch,             'braintree/transaction_search'
  autoload :TransparentRedirect,           'braintree/transparent_redirect'
  autoload :TransparentRedirectGateway,    'braintree/transparent_redirect_gateway'
  autoload :Util,                          'braintree/util'
  autoload :ValidationError,               'braintree/validation_error'
  autoload :ValidationErrorCollection,     'braintree/validation_error_collection'
  autoload :Xml,                           'braintree/xml'
  autoload :Version,                       'braintree/version'
end

require "braintree/exceptions"
