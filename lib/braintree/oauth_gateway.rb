module Braintree
  class OAuthGateway
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def create_token_from_code(params)
      Braintree::SuccessfulResult.new(
        :credentials => Braintree::OAuthCredentials._new(
          :access_token => "foo",
          :refresh_token => "foo",
          :expires_at => "foo",
          :token_type => "bearer",
        )
      )
    end
  end
end
