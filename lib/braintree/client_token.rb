require 'json'

module Braintree
  module ClientToken
    DEFAULT_VERSION = 2

    def self.generate(options={})
      Configuration.gateway.client_token.generate(options)
    end
  end
end
