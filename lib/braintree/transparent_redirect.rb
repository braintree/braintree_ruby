module Braintree
  # See:
  # * http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_tr
  # * http://www.braintreepaymentsolutions.com/docs/ruby/customers/create_tr
  # * http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/create_tr
  # * http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/update_tr
  module TransparentRedirect
    TransparentRedirectKeys = [:redirect_url] # :nodoc:
    CreateCustomerSignature = TransparentRedirectKeys + [{:customer => Customer._create_signature}] # :nodoc:
    UpdateCustomerSignature = TransparentRedirectKeys + [:customer_id, {:customer => Customer._update_signature}] # :nodoc:
    TransactionSignature = TransparentRedirectKeys + [{:transaction => Transaction._create_signature}] # :nodoc:
    CreateCreditCardSignature = TransparentRedirectKeys + [{:credit_card => CreditCard._create_signature}] # :nodoc:
    UpdateCreditCardSignature = TransparentRedirectKeys + [:payment_method_token, {:credit_card => CreditCard._update_signature}] # :nodoc:

    module Kind # :nodoc:
      CreateCustomer = "create_customer"
      UpdateCustomer = "update_customer"
      CreatePaymentMethod = "create_payment_method"
      UpdatePaymentMethod = "update_payment_method"
      CreateTransaction = "create_transaction"
    end

    def self.confirm(query_string)
      params = TransparentRedirect.parse_and_validate_query_string query_string
      confirmation_klass = {
        Kind::CreateCustomer => Braintree::Customer,
        Kind::UpdateCustomer => Braintree::Customer,
        Kind::CreatePaymentMethod => Braintree::CreditCard,
        Kind::UpdatePaymentMethod => Braintree::CreditCard,
        Kind::CreateTransaction => Braintree::Transaction
      }[params[:kind]]

      confirmation_klass._do_create("/transparent_redirect_requests/#{params[:id]}/confirm")
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/create_tr
    def self.create_credit_card_data(params)
      Util.verify_keys(CreateCreditCardSignature, params)
      params[:kind] = Kind::CreatePaymentMethod
      _data(params)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/customers/create_tr
    def self.create_customer_data(params)
      Util.verify_keys(CreateCustomerSignature, params)
      params[:kind] = Kind::CreateCustomer
      _data(params)
    end

    def self.parse_and_validate_query_string(query_string) # :nodoc:
      params = Util.symbolize_keys(Util.parse_query_string(query_string))
      query_string_without_hash = query_string[/(.*)&hash=.*/, 1]

      if params[:http_status] == nil
        raise UnexpectedError, "expected query string to have an http_status param"
      elsif params[:http_status] != '200'
        Util.raise_exception_for_status_code(params[:http_status], params[:bt_message])
      end

      if _hash(query_string_without_hash) == params[:hash]
        params
      else
        raise ForgedQueryString
      end
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_tr
    def self.transaction_data(params)
      Util.verify_keys(TransactionSignature, params)
      params[:kind] = Kind::CreateTransaction
      transaction_type = params[:transaction] && params[:transaction][:type]
      unless %w[sale credit].include?(transaction_type)
        raise ArgumentError, "expected transaction[type] of sale or credit, was: #{transaction_type.inspect}"
      end
      _data(params)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/credit_cards/update_tr
    def self.update_credit_card_data(params)
      Util.verify_keys(UpdateCreditCardSignature, params)
      unless params[:payment_method_token]
        raise ArgumentError, "expected params to contain :payment_method_token of payment method to update"
      end
      params[:kind] = Kind::UpdatePaymentMethod
      _data(params)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/customers/update_tr
    def self.update_customer_data(params)
      Util.verify_keys(UpdateCustomerSignature, params)
      unless params[:customer_id]
        raise ArgumentError, "expected params to contain :customer_id of customer to update"
      end
      params[:kind] = Kind::UpdateCustomer
      _data(params)
    end

    # Returns the URL to which Transparent Redirect Requests should be posted
    def self.url
      "#{Braintree::Configuration.base_merchant_url}/transparent_redirect_requests"
    end

    def self._data(params) # :nodoc:
      raise ArgumentError, "expected params to contain :redirect_url" unless params[:redirect_url]
      tr_data_segment = Util.hash_to_query_string(params.merge(
        :api_version => Configuration::API_VERSION,
        :time => Time.now.utc.strftime("%Y%m%d%H%M%S"),
        :public_key => Configuration.public_key
      ))
      tr_data_hash = _hash(tr_data_segment)
      "#{tr_data_hash}|#{tr_data_segment}"
    end

    def self._hash(string) # :nodoc:
      ::Braintree::Digest.hexdigest(string)
    end
  end
end
