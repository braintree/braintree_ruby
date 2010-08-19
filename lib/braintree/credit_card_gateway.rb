module Braintree
  class CreditCardGateway # :nodoc:
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def create(attributes)
      if attributes.has_key?(:expiration_date) && (attributes.has_key?(:expiration_month) || attributes.has_key?(:expiration_year))
        raise ArgumentError.new("create with both expiration_month and expiration_year or only expiration_date")
      end
      Util.verify_keys(CreditCardGateway._create_signature, attributes)
      _do_create("/payment_methods", :credit_card => attributes)
    end

    # Deprecated
    def create_credit_card_url
      "#{@config.base_merchant_url}/payment_methods/all/create_via_transparent_redirect_request"
    end

    # Deprecated
    def create_from_transparent_redirect(query_string)
      params = @gateway.transparent_redirect.parse_and_validate_query_string query_string
      _do_create("/payment_methods/all/confirm_transparent_redirect_request", :id => params[:id])
    end

    def delete(token)
      @config.http.delete("/payment_methods/#{token}")
    end

    def expired(options = {})
      response = @config.http.post("/payment_methods/all/expired_ids")
      ResourceCollection.new(response) { |ids| _fetch_expired(ids) }
    end

    def expiring_between(start_date, end_date, options = {})
      formatted_start_date = start_date.strftime('%m%Y')
      formatted_end_date = end_date.strftime('%m%Y')
      response = @config.http.post("/payment_methods/all/expiring_ids?start=#{formatted_start_date}&end=#{formatted_end_date}")
      ResourceCollection.new(response) { |ids| _fetch_expiring_between(formatted_start_date, formatted_end_date, ids) }
    end

    def find(token)
      response = @config.http.get "/payment_methods/#{token}"
      CreditCard._new(@gateway, response[:credit_card])
    rescue NotFoundError
      raise NotFoundError, "payment method with token #{token.inspect} not found"
    end

    def update(token, attributes)
      Util.verify_keys(CreditCardGateway._update_signature, attributes)
      _do_update(:put, "/payment_methods/#{token}", :credit_card => attributes)
    end

    # Deprecated
    def update_from_transparent_redirect(query_string)
      warn "[DEPRECATED] CreditCard.update_via_transparent_redirect_request is deprecated. Please use TransparentRedirect.confirm"
      params = @gateway.transparent_redirect.parse_and_validate_query_string query_string
      _do_update(:post, "/payment_methods/all/confirm_transparent_redirect_request", :id => params[:id])
    end

    # Deprecated
    def update_credit_card_url
      warn "[DEPRECATED] CreditCard.update_credit_card_url is deprecated. Please use TransparentRedirect.url"
      "#{@config.base_merchant_url}/payment_methods/all/update_via_transparent_redirect_request"
    end

    def self._create_signature # :nodoc:
      _signature(:create)
    end

    def self._update_signature # :nodoc:
      _signature(:update)
    end

    def self._signature(type) # :nodoc:
      billing_address_params = AddressGateway._shared_signature
      signature = [
        :cardholder_name, :cvv, :expiration_date, :expiration_month, :expiration_year, :number, :token,
        {:options => [:make_default, :verification_merchant_account_id, :verify_card]},
        {:billing_address => billing_address_params}
      ]

      case type
      when :create
        signature << :customer_id
      when :update
        billing_address_params << {:options => [:update_existing]}
      else
        raise ArgumentError
      end

      return signature
    end

    def _do_create(url, params=nil) # :nodoc:
      response = @config.http.post url, params
      if response[:credit_card]
        SuccessfulResult.new(:credit_card => CreditCard._new(@gateway, response[:credit_card]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :credit_card or :api_error_response"
      end
    end

    def _do_update(http_verb, url, params) # :nodoc:
      response = @config.http.send http_verb, url, params
      if response[:credit_card]
        SuccessfulResult.new(:credit_card => CreditCard._new(@gateway, response[:credit_card]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :credit_card or :api_error_response"
      end
    end

    def _fetch_expired(ids) # :nodoc:
      response = @config.http.post("/payment_methods/all/expired", :search => {:ids => ids})
      attributes = response[:payment_methods]
      Util.extract_attribute_as_array(attributes, :credit_card).map { |attrs| CreditCard._new(@gateway, attrs) }
    end

    def _fetch_expiring_between(formatted_start_date, formatted_end_date, ids) # :nodoc:
      response = @config.http.post(
        "/payment_methods/all/expiring?start=#{formatted_start_date}&end=#{formatted_end_date}",
        :search => {:ids => ids}
      )
      attributes = response[:payment_methods]
      Util.extract_attribute_as_array(attributes, :credit_card).map { |attrs| CreditCard._new(@gateway, attrs) }
    end
  end
end
