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

    def cancel_release(transaction_id)
      raise ArgumentError, "transaction_id is invalid" unless transaction_id =~ /\A[0-9a-z]+\z/
      response = @config.http.put "/transactions/#{transaction_id}/cancel_release"
      _handle_transaction_response(response)
    end

    def hold_in_escrow(transaction_id)
      raise ArgumentError, "transaction_id is invalid" unless transaction_id =~ /\A[0-9a-z]+\z/
      response = @config.http.put "/transactions/#{transaction_id}/hold_in_escrow"
      _handle_transaction_response(response)
    end

    def _handle_transaction_response(response)
      if response[:transaction]
        SuccessfulResult.new(:transaction => Transaction._new(@gateway, response[:transaction]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :transaction or :response"
      end
    end

    def clone_transaction(transaction_id, attributes)
      Util.verify_keys(TransactionGateway._clone_signature, attributes)
      _do_create "/transactions/#{transaction_id}/clone", :transaction_clone => attributes
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
      raise ArgumentError if id.nil? || id.strip.to_s == ""
      response = @config.http.get "/transactions/#{id}"
      Transaction._new(@gateway, response[:transaction])
    rescue NotFoundError
      raise NotFoundError, "transaction with id #{id.inspect} not found"
    end

    def refund(transaction_id, amount = nil)
      response = @config.http.post "/transactions/#{transaction_id}/refund", :transaction => {:amount => amount}
      _handle_transaction_response(response)
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

      if response.has_key?(:search_results)
        ResourceCollection.new(response) { |ids| _fetch_transactions(search, ids) }
      else
        raise DownForMaintenanceError
      end
    end

    def release_from_escrow(transaction_id)
      raise ArgumentError, "transaction_id is invalid" unless transaction_id =~ /\A[0-9a-z]+\z/
      response = @config.http.put "/transactions/#{transaction_id}/release_from_escrow"
      _handle_transaction_response(response)
    end

    def submit_for_settlement(transaction_id, amount = nil)
      raise ArgumentError, "transaction_id is invalid" unless transaction_id =~ /\A[0-9a-z]+\z/
      response = @config.http.put "/transactions/#{transaction_id}/submit_for_settlement", :transaction => {:amount => amount}
      _handle_transaction_response(response)
    end

    def void(transaction_id)
      response = @config.http.put "/transactions/#{transaction_id}/void"
      _handle_transaction_response(response)
    end

    def self._clone_signature # :nodoc:
      [:amount, :channel, {:options => [:submit_for_settlement]}]
    end

    def self._create_signature # :nodoc:
      [
        :amount, :customer_id, :merchant_account_id, :order_id, :channel, :payment_method_token,
        :purchase_order_number, :recurring, :shipping_address_id, :type, :tax_amount, :tax_exempt,
        :venmo_sdk_payment_method_code, :device_session_id, :service_fee_amount, :device_data, :fraud_merchant_id,
        {:credit_card => [:token, :cardholder_name, :cvv, :expiration_date, :expiration_month, :expiration_year, :number]},
        {:customer => [:id, :company, :email, :fax, :first_name, :last_name, :phone, :website]},
        {
          :billing => AddressGateway._shared_signature
        },
        {
          :shipping => AddressGateway._shared_signature
        },
        {:options => [:hold_in_escrow, :store_in_vault, :store_in_vault_on_success, :submit_for_settlement, :add_billing_address_to_payment_method, :store_shipping_address_in_vault, :venmo_sdk_session]},
        {:custom_fields => :_any_key_},
        {:descriptor => [:name, :phone]}
      ]
    end

    def _do_create(url, params=nil) # :nodoc:
      response = @config.http.post url, params
      _handle_transaction_response(response)
    end

    def _fetch_transactions(search, ids) # :nodoc:
      search.ids.in ids
      response = @config.http.post "/transactions/advanced_search", {:search => search.to_hash}
      attributes = response[:credit_card_transactions]
      Util.extract_attribute_as_array(attributes, :transaction).map { |attrs| Transaction._new(@gateway, attrs) }

    rescue Braintree::UnexpectedError
      if $!.to_s =~ /Unprocessable entity/ && ids.size > 1
        # Act under the belief that this is a server-side timeout, not a real invalid
        # request. In that case, we can work around this client-side by requesting
        # fewer IDs -- say, by splitting the request in half -- and trying again.
        #
        # Yes, this is recursive.
        #
        # https://en.wikipedia.org/wiki/The_Sorcerer's_Apprentice
        brooms = [[], []]
        ids.each_with_index { |id,i|
          brooms[i % 2] << id
        }
        _fetch_transactions(search, brooms[0]) + _fetch_transactions(search, brooms[1])
      else
        raise
      end
    end
  end
end
