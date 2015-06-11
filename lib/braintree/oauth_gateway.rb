module Braintree
  class OAuthGateway
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def create_token_from_code(params)
      params[:grant_type] = "authorization_code"
      params = {:credentials => params}
      response = @config.http.post("/oauth/access_tokens", params)
      Braintree::SuccessfulResult.new(
        :credentials => OAuthCredentials._new(response[:credentials])
      )
    end
  end
end
