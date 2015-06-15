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
  end
end
