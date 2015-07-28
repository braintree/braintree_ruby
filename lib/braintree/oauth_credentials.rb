module Braintree
  class OAuthCredentials
    include BaseModule # :nodoc:

    attr_reader :access_token, :refresh_token, :expires_at, :token_type

    def initialize(attributes) # :nodoc:
      set_instance_variables_from_hash(attributes)
    end

    class << self
      protected :new
    end

    def self._new(*args) # :nodoc:
      self.new *args
    end
  end
end
