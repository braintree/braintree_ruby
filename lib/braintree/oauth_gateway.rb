module Braintree
  class OAuthGateway
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
      @config.assert_has_client_credentials
    end

    def create_token_from_code(params)
      params[:grant_type] = "authorization_code"
      _create_token(params)
    end

    def create_token_from_refresh_token(params)
      params[:grant_type] = "refresh_token"
      _create_token(params)
    end

    def _create_token(params)
      response = @config.http.post("/oauth/access_tokens", {
        :credentials => params,
      })
      if response[:credentials]
        Braintree::SuccessfulResult.new(
          :credentials => OAuthCredentials._new(response[:credentials])
        )
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise "expected :credentials or :api_error_response"
      end
    end

    def revoke_access_token(access_token)
      response = @config.http.post("/oauth/revoke_access_token", {
        :token => access_token
      })
      if response[:result][:success] == true
        Braintree::SuccessfulResult.new
      else
        ErrorResult.new(@gateway, "could not revoke access token")
      end
    end

    def connect_url(params)
      params[:client_id] = @config.client_id
      user_params = _sub_query(params, :user)
      business_params = _sub_query(params, :business)
      payment_methods = _sub_array_query(params, :payment_methods)
      query = params.to_a.
        concat(user_params).
        concat(business_params).
        concat(payment_methods)

      query_string = query.map { |k, v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}" }.join("&")
      url = "#{@config.base_url}/oauth/connect?#{query_string}"
      "#{url}&signature=#{_compute_signature(url)}&algorithm=SHA256"
    end

    def _sub_query(params, root)
      sub_params = params.delete(root) || {}
      sub_params.map do |key, value|
        ["#{root}[#{key}]", value]
      end
    end

    def _sub_array_query(params, root)
      sub_params = params.delete(root) || []
      sub_params.map do |value|
        ["#{root}[]", value]
      end
    end

    def _compute_signature(url)
      key_digest = OpenSSL::Digest::SHA256.digest(@config.client_secret)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, key_digest, url)
    end
  end
end
