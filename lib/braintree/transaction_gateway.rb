module Braintree
  class TransactionGateway # :nodoc:
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
      @config.assert_has_access_token_or_keys
    end

    def create(attributes)
      Util.verify_keys(TransactionGateway._create_signature, attributes)
      _do_create "/transactions", :transaction => attributes
    end

    def cancel_release(transaction_id)
      raise ArgumentError, "transaction_id is invalid" unless transaction_id =~ /\A[0-9a-z]+\z/
      response = @config.http.put("#{@config.base_merchant_path}/transactions/#{transaction_id}/cancel_release")
      _handle_transaction_response(response)
    end

    def hold_in_escrow(transaction_id)
      raise ArgumentError, "transaction_id is invalid" unless transaction_id =~ /\A[0-9a-z]+\z/
      response = @config.http.put("#{@config.base_merchant_path}/transactions/#{transaction_id}/hold_in_escrow")
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
      response = @config.http.get("#{@config.base_merchant_path}/transactions/#{id}")
      Transaction._new(@gateway, response[:transaction])
    rescue NotFoundError
      raise NotFoundError, "transaction with id #{id.inspect} not found"
    end

    def refund(transaction_id, amount = nil)
      response = @config.http.post("#{@config.base_merchant_path}/transactions/#{transaction_id}/refund", :transaction => {:amount => amount})
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

      response = @config.http.post("#{@config.base_merchant_path}/transactions/advanced_search_ids", {:search => search.to_hash})

      if response.has_key?(:search_results)
        ResourceCollection.new(response) { |ids| _fetch_transactions(search, ids) }
      else
        raise DownForMaintenanceError
      end
    end

    def release_from_escrow(transaction_id)
      raise ArgumentError, "transaction_id is invalid" unless transaction_id =~ /\A[0-9a-z]+\z/
      response = @config.http.put("#{@config.base_merchant_path}/transactions/#{transaction_id}/release_from_escrow")
      _handle_transaction_response(response)
    end

    def submit_for_settlement(transaction_id, amount = nil)
      raise ArgumentError, "transaction_id is invalid" unless transaction_id =~ /\A[0-9a-z]+\z/
      response = @config.http.put("#{@config.base_merchant_path}/transactions/#{transaction_id}/submit_for_settlement", :transaction => {:amount => amount})
      _handle_transaction_response(response)
    end

    def submit_for_partial_settlement(authorized_transaction_id, amount = nil)
      raise ArgumentError, "authorized_transaction_id is invalid" unless authorized_transaction_id =~ /\A[0-9a-z]+\z/
      response = @config.http.post("#{@config.base_merchant_path}/transactions/#{authorized_transaction_id}/submit_for_partial_settlement", :transaction => {:amount => amount})
      _handle_transaction_response(response)
    end

    def void(transaction_id)
      response = @config.http.put("#{@config.base_merchant_path}/transactions/#{transaction_id}/void")
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
        :billing_address_id, :payment_method_nonce, :three_d_secure_token,
        :shared_payment_method_token, :shared_billing_address_id, :shared_customer_id, :shared_shipping_address_id,
        {:credit_card => [:token, :cardholder_name, :cvv, :expiration_date, :expiration_month, :expiration_year, :number]},
        {:customer => [:id, :company, :email, :fax, :first_name, :last_name, :phone, :website]},
        {
          :billing => AddressGateway._shared_signature
        },
        {
          :shipping => AddressGateway._shared_signature
        },
        {:options => [
          :hold_in_escrow,
          :store_in_vault,
          :store_in_vault_on_success,
          :submit_for_settlement,
          :add_billing_address_to_payment_method,
          :store_shipping_address_in_vault,
          :venmo_sdk_session,
          :payee_email,
          {:paypal => [:custom_field, :payee_email, :description]},
          {:three_d_secure => [:required]},
          {:amex_rewards => [:request_id, :points, :currency_amount, :currency_iso_code]}]
        },
        {:custom_fields => :_any_key_},
        {:descriptor => [:name, :phone, :url]},
        {:paypal_account => [:email, :token, :paypal_data, :payee_email]},
        {:industry => [:industry_type, {:data => [:folio_number, :check_in_date, :check_out_date, :travel_package, :lodging_check_in_date, :lodging_check_out_date, :departure_date, :lodging_name, :room_rate]}]}
      ]
    end

    def _do_create(path, params=nil) # :nodoc:
      response = @config.http.post("#{@config.base_merchant_path}#{path}", params)
      _handle_transaction_response(response)
    end

    def _fetch_transactions(search, ids) # :nodoc:
      search.ids.in ids
      response = @config.http.post("#{@config.base_merchant_path}/transactions/advanced_search", {:search => search.to_hash})
      attributes = response[:credit_card_transactions]
      Util.extract_attribute_as_array(attributes, :transaction).map { |attrs| Transaction._new(@gateway, attrs) }
    end
  end
end
