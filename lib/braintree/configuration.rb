module Braintree
  # The following configuration attributes need to be set to use the gem:
  # * merchant_id
  # * public_key
  # * private_key
  # * environment
  #
  # By default, the logger will log to +STDOUT+. The log level is set to info.
  # The logger can be set to any Logger object.
  module Configuration
    API_VERSION = "1" # :nodoc:

    class << self
      attr_accessor :logger
      attr_writer :merchant_id, :public_key, :private_key
    end
  
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
  
    def self.base_merchant_url # :nodoc:
      "#{protocol}://#{server}:#{port}#{base_merchant_path}"
    end
  
    def self.base_merchant_path # :nodoc:
      "/merchants/#{Braintree::Configuration.merchant_id}"
    end

    def self.ca_file # :nodoc:
      case environment
      when :qa, :sandbox
        File.expand_path(File.join(File.dirname(__FILE__), "..", "ssl", "valicert_ca.crt"))
      when :production
        File.expand_path(File.join(File.dirname(__FILE__), "..", "ssl", "securetrust_ca.crt"))
      end
    end
 
    # Sets the Braintree environment to use. Valid values are <tt>:sandbox</tt> and <tt>:production</tt> 
    def self.environment=(env)
      unless [:development, :qa, :sandbox, :production].include?(env)
        raise ArgumentError, "#{env.inspect} is not a valid environment"
      end
      @environment = env
    end
  
    def self.logger # :nodoc:
      @logger ||= _default_logger
    end
  
    def self.port # :nodoc:
      case environment
      when :development
        3000
      when :production, :qa, :sandbox
        443
      end
    end
  
    def self.protocol # :nodoc:
      ssl? ? "https" : "http"
    end
  
    def self.server # :nodoc:
      case environment
      when :development
        "localhost"
      when :production
        "www.braintreegateway.com"
      when :qa
        "qa.braintreegateway.com"
      when :sandbox
        "sandbox.braintreegateway.com"
      end    
    end  
    
    def self.ssl? # :nodoc:
      case environment
      when :development
        false
      when :production, :qa, :sandbox
        true
      end    
    end
  
    def self._default_logger # :nodoc:
      logger = Logger.new(STDOUT)
      logger.level = Logger::INFO
      logger
    end  
  end
end
