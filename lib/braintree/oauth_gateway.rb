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

    def connect_url(params)
      params[:client_id] = @config.client_id
      user_params = _sub_query(params, :user)
      business_params = _sub_query(params, :business)
      query = params.
        merge(user_params).
        merge(business_params).
        merge(:client_id => @config.client_id)

      query_string = query.map { |k, v| "#{URI.escape(k.to_s)}=#{URI.escape(v.to_s)}" }.join("&")
      _sign_url("#{@config.base_url}/oauth/connect?#{query_string}")
    end

    def _sub_query(params, root)
      sub_params = params.delete(root) || {}
      sub_params.reduce({}) do |query, (key, value)|
        query["#{root}[#{key}]"] = value
        query
      end
    end

    def _sign_url(url)
      signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), @config.client_secret, url)
      "#{url}&signature=#{signature}&algorithm=SHA256"
    end
  end
end
