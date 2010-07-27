module Braintree # :nodoc:
  # Super class for all Braintree exceptions.
  class BraintreeError < ::StandardError; end

  # See http://www.braintreepaymentsolutions.com/docs/ruby/general/exceptions
  class AuthenticationError < BraintreeError; end

  # See http://www.braintreepaymentsolutions.com/docs/ruby/general/exceptions
  class AuthorizationError < BraintreeError; end

  # See http://www.braintreepaymentsolutions.com/docs/ruby/general/exceptions
  class ConfigurationError < BraintreeError
    def initialize(setting, message) # :nodoc:
      super "Braintree::Configuration.#{setting} #{message}"
    end
  end

  # See http://www.braintreepaymentsolutions.com/docs/ruby/general/exceptions
  class DownForMaintenanceError < BraintreeError; end

  # See http://www.braintreepaymentsolutions.com/docs/ruby/general/exceptions
  class ForgedQueryString < BraintreeError; end

  # See http://www.braintreepaymentsolutions.com/docs/ruby/general/exceptions
  class NotFoundError < BraintreeError; end

  # See http://www.braintreepaymentsolutions.com/docs/ruby/general/exceptions
  class ServerError < BraintreeError; end

  # See http://www.braintreepaymentsolutions.com/docs/ruby/general/exceptions
  class SSLCertificateError < BraintreeError; end

  # See http://www.braintreepaymentsolutions.com/docs/ruby/general/exceptions
  class UnexpectedError < BraintreeError; end

  # See http://www.braintreepaymentsolutions.com/docs/ruby/general/exceptions
  class UpgradeRequiredError < BraintreeError; end

  # See http://www.braintreepaymentsolutions.com/docs/ruby/general/exceptions
  class ValidationsFailed < BraintreeError
    attr_reader :error_result

    def initialize(error_result)
      @error_result = error_result
    end

    def inspect
      "#<#{self.class} error_result: #{@error_result.inspect}>"
    end

    def to_s
      inspect
    end
  end
end

