module Braintree
  class CustomerGateway # :nodoc:
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def all
      response = @config.http.post "/customers/advanced_search_ids"
      ResourceCollection.new(response) { |ids| _fetch_customers(ids) }
    end

    def create(attributes = {})
      Util.verify_keys(CustomerGateway._create_signature, attributes)
      _do_create "/customers", :customer => attributes
    end

    # Deprecated
    def create_customer_url
      "#{@config.base_merchant_url}/customers/all/create_via_transparent_redirect_request"
    end

    # Deprecated
    def create_from_transparent_redirect(query_string)
      params = @gateway.transparent_redirect.parse_and_validate_query_string query_string
      _do_create("/customers/all/confirm_transparent_redirect_request", :id => params[:id])
    end

    def delete(customer_id)
      @config.http.delete("/customers/#{customer_id}")
      SuccessfulResult.new
    end

    def find(customer_id)
      raise ArgumentError, "customer_id contains invalid characters" unless customer_id.to_s =~ /\A[\w-]+\z/
      raise ArgumentError, "customer_id cannot be blank" if customer_id.to_s == ""
      response = @config.http.get("/customers/#{customer_id}")
      Customer._new(@gateway, response[:customer])
    rescue NotFoundError
      raise NotFoundError, "customer with id #{customer_id.inspect} not found"
    end

    def transactions(customer_id, options = {})
      response = @config.http.post "/customers/#{customer_id}/transaction_ids"
      ResourceCollection.new(response) { |ids| _fetch_transactions(customer_id, ids) }
    end

    def update(customer_id, attributes)
      Util.verify_keys(CustomerGateway._update_signature, attributes)
      _do_update(:put, "/customers/#{customer_id}", :customer => attributes)
    end

    # Deprecated
    def update_customer_url
      warn "[DEPRECATED] Customer.update_customer_url is deprecated. Please use TransparentRedirect.url"
      "#{@config.base_merchant_url}/customers/all/update_via_transparent_redirect_request"
    end

    # Deprecated
    def update_from_transparent_redirect(query_string)
      params = @gateway.transparent_redirect.parse_and_validate_query_string(query_string)
      _do_update(:post, "/customers/all/confirm_transparent_redirect_request", :id => params[:id])
    end

    def self._create_signature # :nodoc:
      credit_card_signature = CreditCardGateway._create_signature - [:customer_id]
      [
        :company, :email, :fax, :first_name, :id, :last_name, :phone, :website,
        {:credit_card => credit_card_signature},
        {:custom_fields => :_any_key_}
      ]
    end

    def _do_create(url, params=nil) # :nodoc:
      response = @config.http.post url, params
      if response[:customer]
        SuccessfulResult.new(:customer => Customer._new(@gateway, response[:customer]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise "expected :customer or :api_error_response"
      end
    end

    def _do_update(http_verb, url, params) # :nodoc:
      response = @config.http.send http_verb, url, params
      if response[:customer]
        SuccessfulResult.new(:customer => Customer._new(@gateway, response[:customer]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :customer or :api_error_response"
      end
    end

    def _fetch_customers(ids) # :nodoc:
      response = @config.http.post "/customers/advanced_search", {:search => {:ids => ids}}
      attributes = response[:customers]
      Util.extract_attribute_as_array(attributes, :customer).map { |attrs| Customer._new(@gateway, attrs) }
    end

    def _fetch_transactions(customer_id, ids) # :nodoc:
      response = @config.http.post "/customers/#{customer_id}/transactions", :search => {:ids => ids}
      attributes = response[:credit_card_transactions]
      Util.extract_attribute_as_array(attributes, :transaction).map do |transaction_attributes|
        Transaction._new @gateway, transaction_attributes
      end
    end

    def self._update_signature # :nodoc:
      credit_card_signature = CreditCardGateway._update_signature - [:customer_id]
      credit_card_options = credit_card_signature.find { |item| item.respond_to?(:keys) && item.keys == [:options] }
      credit_card_options[:options] << :update_existing_token
      [
        :company, :email, :fax, :first_name, :id, :last_name, :phone, :website,
        {:credit_card => credit_card_signature},
        {:custom_fields => :_any_key_}
      ]
    end
  end
end
