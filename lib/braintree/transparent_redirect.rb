module Braintree
  # See:
  # * http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_tr
  # * http://www.braintreepaymentsolutions.com/docs/ruby/customers/create_tr
  # * http://www.braintreepaymentsolutions.com/docs/ruby/customers/update_tr
  # * http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/create_tr
  # * http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/update_tr
  module TransparentRedirect
    module Kind # :nodoc:
      CreateCustomer = "create_customer"
      UpdateCustomer = "update_customer"
      CreatePaymentMethod = "create_payment_method"
      UpdatePaymentMethod = "update_payment_method"
      CreateTransaction = "create_transaction"
    end

    def self.confirm(query_string)
      Configuration.gateway.transparent_redirect.confirm(query_string)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/create_tr
    def self.create_credit_card_data(params)
      Configuration.gateway.transparent_redirect.create_credit_card_data(params)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/customers/create_tr
    def self.create_customer_data(params)
      Configuration.gateway.transparent_redirect.create_customer_data(params)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_tr
    def self.transaction_data(params)
      Configuration.gateway.transparent_redirect.transaction_data(params)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/update_tr
    def self.update_credit_card_data(params)
      Configuration.gateway.transparent_redirect.update_credit_card_data(params)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/customers/update_tr
    def self.update_customer_data(params)
      Configuration.gateway.transparent_redirect.update_customer_data(params)
    end

    # Returns the URL to which Transparent Redirect Requests should be posted
    def self.url
      Configuration.gateway.transparent_redirect.url
    end
  end
end
