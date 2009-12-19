module Braintree
  # The TransparentRedirect module provides methods to build the tr_data param
  # that must be submitted when using the transparent redirect API. For more information
  # about transparent redirect, see (TODO).
  #
  # You must provide a redirect_url that the gateway will redirect the user to when the
  # action is complete.
  #
  #   tr_data = Braintree::TransparentRedirect.create_customer_data(
  #     :redirect_url => "http://example.com/redirect_back_to_merchant_site
  #   )
  #
  # In addition to the redirect_url, any data that needs to be protected from user tampering
  # should be included in the tr_data. For example, to prevent the user from tampering with the transaction
  # amount, include the amount in the tr_data.
  #
  #   tr_data = Braintree::TransparentRedirect.transaction_data(
  #     :redirect_url => "http://example.com/complete_transaction",
  #     :transaction => {:amount => "100.00"}
  #   )
  module TransparentRedirect
    TransparentRedirectKeys = [:redirect_url] # :nodoc:
    CreateCustomerSignature = TransparentRedirectKeys + [{:customer => Customer._create_signature}] # :nodoc:
    UpdateCustomerSignature = TransparentRedirectKeys + [:customer_id, {:customer => Customer._update_signature}] # :nodoc:
    TransactionSignature = TransparentRedirectKeys + [{:transaction => Transaction._create_signature}] # :nodoc:
    CreateCreditCardSignature = TransparentRedirectKeys + [{:credit_card => CreditCard._create_signature}] # :nodoc:
    UpdateCreditCardSignature = TransparentRedirectKeys + [:payment_method_token, {:credit_card => CreditCard._update_signature}] # :nodoc:

    # Returns the tr_data string for creating a credit card.
    def self.create_credit_card_data(params)
      Util.verify_keys(CreateCreditCardSignature, params)
      _data(params)
    end

    # Returns the tr_data string for creating a customer.
    def self.create_customer_data(params)
      Util.verify_keys(CreateCustomerSignature, params)
      _data(params)
    end

    # Returns the tr_data string for creating a transaction.
    def self.transaction_data(params)
      Util.verify_keys(TransactionSignature, params)
      transaction_type = params[:transaction] && params[:transaction][:type]
      unless %w[sale credit].include?(transaction_type)
        raise ArgumentError, "expected transaction[type] of sale or credit, was: #{transaction_type.inspect}"
      end
      _data(params)
    end

    # Returns the tr_data string for updating a credit card.
    # The payment_method_token of the credit card to update is required.
    #
    #   tr_data = Braintree::TransparentRedirect.update_credit_card_data(
    #     :redirect_url => "http://example.com/redirect_here",
    #     :payment_method_token => "token123"
    #   )
    def self.update_credit_card_data(params)
      Util.verify_keys(UpdateCreditCardSignature, params)
      unless params[:payment_method_token]
        raise ArgumentError, "expected params to contain :payment_method_token of payment method to update"
      end
      _data(params)
    end

    # Returns the tr_data string for updating a customer.
    # The customer_id of the customer to update is required.
    #
    #   tr_data = Braintree::TransparentRedirect.update_customer_data(
    #     :redirect_url => "http://example.com/redirect_here",
    #     :customer_id => "customer123"
    #   )
    def self.update_customer_data(params)
      Util.verify_keys(UpdateCustomerSignature, params)
      unless params[:customer_id]
        raise ArgumentError, "expected params to contain :customer_id of customer to update"
      end
      _data(params)
    end

    def self.parse_and_validate_query_string(query_string) # :nodoc:
      params = Util.symbolize_keys(Util.parse_query_string(query_string))
      query_string_without_hash = query_string[/(.*)&hash=.*/, 1]
      if _hash(query_string_without_hash) == params[:hash]
        if params[:http_status] == '200'
          params
        else
          Util.raise_exception_for_status_code(params[:http_status])
        end
      else
        raise ForgedQueryString
      end
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
