module Braintree
  class TransactionGateway # :nodoc:
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def create(attributes)
      Util.verify_keys(TransactionGateway._create_signature, attributes)
      _do_create "/transactions", :transaction => attributes
    end

    # Deprecated
    def create_from_transparent_redirect(query_string)
      params = @gateway.transparent_redirect.parse_and_validate_query_string query_string
      _do_create("/transactions/all/confirm_transparent_redirect_request", :id => params[:id])
    end

    def create_transaction_url
      warn "[DEPRECATED] Transaction.create_transaction_url is deprecated. Please use TransparentRedirect.url"
      "#{@config.base_merchant_url}/transactions/all/create_via_transparent_redirect_request"
    end

    def credit(attributes)
      create(attributes.merge(:type => 'credit'))
    end

    def find(id)
      response = @config.http.get "/transactions/#{id}"
      Transaction._new(@gateway, response[:transaction])
    rescue NotFoundError
      raise NotFoundError, "transaction with id #{id.inspect} not found"
    end

    def refund(transaction_id, amount = nil)
      response = @config.http.post "/transactions/#{transaction_id}/refund", :transaction => {:amount => amount}
      if response[:transaction]
        SuccessfulResult.new(:transaction => Transaction._new(@gateway, response[:transaction]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :transaction or :api_error_response"
      end
    end

    def retry_subscription_charge(subscription_id, amount=nil)
      attributes = {
        :amount => amount,
        :subscription_id => subscription_id,
        :type => Transaction::Type::Sale
      }
      _do_create "/transactions", :transaction => attributes
    end

    def sale(attributes)
      create(attributes.merge(:type => 'sale'))
    end

    def search(&block)
      search = TransactionSearch.new
      block.call(search) if block

      response = @config.http.post "/transactions/advanced_search_ids", {:search => search.to_hash}
      ResourceCollection.new(response) { |ids| _fetch_transactions(search, ids) }
    end

    def submit_for_settlement(transaction_id, amount = nil)
      raise ArgumentError, "transaction_id is invalid" unless transaction_id =~ /\A[0-9a-z]+\z/
      response = @config.http.put "/transactions/#{transaction_id}/submit_for_settlement", :transaction => {:amount => amount}
      if response[:transaction]
        SuccessfulResult.new(:transaction => Transaction._new(@gateway, response[:transaction]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :transaction or :response"
      end
    end

    def void(transaction_id)
      response = @config.http.put "/transactions/#{transaction_id}/void"
      if response[:transaction]
        SuccessfulResult.new(:transaction => Transaction._new(@gateway, response[:transaction]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :transaction or :api_error_response"
      end
    end

    def self._create_signature # :nodoc:
      [
        :amount, :customer_id, :merchant_account_id, :order_id, :payment_method_token, :type,
        {:credit_card => [:token, :cardholder_name, :cvv, :expiration_date, :expiration_month, :expiration_year, :number]},
        {:customer => [:id, :company, :email, :fax, :first_name, :last_name, :phone, :website]},
        {
          :billing => AddressGateway._shared_signature
        },
        {
          :shipping => AddressGateway._shared_signature
        },
        {:options => [:store_in_vault, :submit_for_settlement, :add_billing_address_to_payment_method, :store_shipping_address_in_vault]},
        {:custom_fields => :_any_key_}
      ]
    end

    def _do_create(url, params=nil) # :nodoc:
      response = @config.http.post url, params
      if response[:transaction]
        SuccessfulResult.new(:transaction => Transaction._new(@gateway, response[:transaction]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :transaction or :api_error_response"
      end
    end

    def _fetch_transactions(search, ids) # :nodoc:
      search.ids.in ids
      response = @config.http.post "/transactions/advanced_search", {:search => search.to_hash}
      attributes = response[:credit_card_transactions]
      Util.extract_attribute_as_array(attributes, :transaction).map { |attrs| Transaction._new(@gateway, attrs) }
    end
  end
end
