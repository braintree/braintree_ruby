require 'json'

module Braintree
  module ClientToken
    def self.generate(options={})
      Configuration.gateway.client_token.generate(options)
    end
  end
end
