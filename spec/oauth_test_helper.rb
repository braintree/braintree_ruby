module Braintree
  class OAuthTestHelper
    def self.create_grant(gateway, params)
      response = gateway.config.http.post("/oauth_testing/grants", {
        :grant => params
      })
      response[:grant][:code]
    end
  end
end
