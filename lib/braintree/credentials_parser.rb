module Braintree
  class CredentialsParser
    attr_reader :client_id, :client_secret, :environment

    def initialize(params)
      @client_id = params[:client_id]
      raise ConfigurationError.new("Missing client_id when constructing Braintree::Gateway") if @client_id.nil?
      raise ConfigurationError.new("Value passed for client_id is not a client_id") unless @client_id.start_with?("client_id")

      @client_secret = params[:client_secret]
      raise ConfigurationError.new("Missing client_secret when constructing Braintree::Gateway") if @client_secret.nil?
      raise ConfigurationError.new("Value passed for client_secret is not a client_secret") unless @client_secret.start_with?("client_secret")

      client_id_environment = parse_environment(@client_id)
      client_secret_environment = parse_environment(@client_secret)

      if client_id_environment != client_secret_environment
        raise ConfigurationError.new("Mismatched credential environments: client_id environment is #{client_id_environment} and client_secret environment is #{client_secret_environment}")
      end

      @environment = client_id_environment
    end

    def parse_environment(credential)
      credential.split("$")[1].to_sym
    end
  end
end
