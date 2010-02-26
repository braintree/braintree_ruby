module Braintree # :nodoc:
  # Super class for all Braintree exceptions.
  class BraintreeError < ::StandardError; end

  # Raised when authentication fails. This may be caused by an incorrect <tt>Braintree::Configuration</tt>
  class AuthenticationError < BraintreeError; end

  # Raised when the API key being used is not authorized to perform the attempted action according
  # to the roles assigned to the user who owns the API key.
  class AuthorizationError < BraintreeError; end

  # Raised when the Braintree gem is not completely configured. See <tt>Braintree::Configuration</tt>.
  class ConfigurationError < BraintreeError
    def initialize(setting, message) # :nodoc:
      super "Braintree::Configuration.#{setting} #{message}"
    end
  end

  # Raised when the gateway is down for maintenance.
  class DownForMaintenanceError < BraintreeError; end

  # Raised from methods that confirm transparent request requests
  # when the given query string cannot be verified. This may indicate
  # an attempted hack on the merchant's transparent redirect
  # confirmation URL.
  class ForgedQueryString < BraintreeError; end

  # Raised when a record could not be found.
  class NotFoundError < BraintreeError; end

  # Raised when an unexpected server error occurs.
  class ServerError < BraintreeError; end

  # Raised when the SSL certificate fails verification.
  class SSLCertificateError < BraintreeError; end

  # Raised when an error occurs that the client library is not built to handle.
  # This shouldn't happen.
  class UnexpectedError < BraintreeError; end

  # Raised from bang methods when validations fail.
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

