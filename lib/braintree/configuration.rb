module Braintree
  # See http://www.braintreepayments.com/docs/ruby
  class Configuration
    API_VERSION = "4" # :nodoc:
    DEFAULT_ENDPOINT = "api" # :nodoc:

    class << self
      attr_writer :custom_user_agent, :endpoint, :logger, :merchant_id, :public_key, :private_key
    end
    attr_reader :merchant_id, :public_key, :private_key

    def self.expectant_reader(*attributes) # :nodoc:
      attributes.each do |attribute|
        (class << self; self; end).send(:define_method, attribute) do
          attribute_value = instance_variable_get("@#{attribute}")
          raise ConfigurationError.new(attribute.to_s, "needs to be set") unless attribute_value
          attribute_value
        end
      end
    end
    expectant_reader :environment, :merchant_id, :public_key, :private_key

    # Sets the Braintree environment to use. Valid values are <tt>:sandbox</tt> and <tt>:production</tt>
    def self.environment=(env)
      unless [:development, :qa, :sandbox, :production].include?(env)
        raise ArgumentError, "#{env.inspect} is not a valid environment"
      end
      @environment = env
    end

    def self.gateway # :nodoc:
      Braintree::Gateway.new(instantiate)
    end

    def self.instantiate # :nodoc:
      config = new(
        :custom_user_agent => @custom_user_agent,
        :endpoint => @endpoint,
        :environment => environment,
        :logger => logger,
        :merchant_id => merchant_id,
        :private_key => private_key,
        :public_key => public_key
      )
    end

    def self.logger
      @logger ||= _default_logger
    end

    def self.signature_service
      instantiate.signature_service
    end

    def self.sha256_signature_service
      instantiate.sha256_signature_service
    end

    def initialize(options = {})
      [:endpoint, :environment, :public_key, :private_key, :custom_user_agent, :logger].each do |attr|
        instance_variable_set "@#{attr}", options[attr]
      end

      @merchant_id = options[:merchant_id] || options[:partner_id]
    end

    def api_version # :nodoc:
      API_VERSION
    end

    def base_merchant_path # :nodoc:
      "/merchants/#{merchant_id}"
    end

    def base_merchant_url # :nodoc:
      "#{protocol}://#{server}:#{port}#{base_merchant_path}"
    end

    def ca_file # :nodoc:
      File.expand_path(File.join(File.dirname(__FILE__), "..", "ssl", "api_braintreegateway_com.ca.crt"))
    end

    def endpoint
      @endpoint || DEFAULT_ENDPOINT
    end

    def http # :nodoc:
      Http.new(self)
    end

    def logger
      @logger ||= self.class._default_logger
    end

    def port # :nodoc:
      case @environment
      when :development
        ENV['GATEWAY_PORT'] || 3000
      when :production, :qa, :sandbox
        443
      end
    end

    def protocol # :nodoc:
      ssl? ? "https" : "http"
    end

    def server # :nodoc:
      case @environment
      when :development
        "localhost"
      when :production
        "#{endpoint}.braintreegateway.com"
      when :qa
        "qa.braintreegateway.com"
      when :sandbox
        "api.sandbox.braintreegateway.com"
      end
    end

    def auth_url
      case @environment
      when :development
        "http://auth.venmo.dev:9292"
      when :production
        "https://auth.venmo.com"
      when :qa
        "https://auth.venmo.qa2.braintreegateway.com"
      when :sandbox
        "https://auth.venmo.sandbox.braintreegateway.com"
      end
    end

    def ssl? # :nodoc:
      case @environment
      when :development
        false
      when :production, :qa, :sandbox
        true
      end
    end

    def user_agent # :nodoc:
      base_user_agent = "Braintree Ruby Gem #{Braintree::Version::String}"
      @custom_user_agent ? "#{base_user_agent} (#{@custom_user_agent})" : base_user_agent
    end

    def self._default_logger # :nodoc:
      logger = Logger.new(STDOUT)
      logger.level = Logger::INFO
      logger
    end

    def inspect
      super.gsub(/@private_key=\".*\"/, '@private_key="[FILTERED]"')
    end

    def signature_service
      @signature_service ||= SignatureService.new(@private_key)
    end

    def sha256_signature_service
      @sha256_signature_service ||= SignatureService.new(@private_key, SHA256Digest)
    end
  end
end
