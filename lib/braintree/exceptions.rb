module Braintree # :nodoc:
  # Super class for all Braintree exceptions.
  class BraintreeError < ::StandardError; end

  class AuthenticationError < BraintreeError; end

  class AuthorizationError < BraintreeError; end

  class ConfigurationError < BraintreeError; end

  class GatewayTimeoutError < BraintreeError; end

  class InvalidSignature < BraintreeError; end

  class InvalidChallenge < BraintreeError; end

  class NotFoundError < BraintreeError; end

  class RequestTimeoutError < BraintreeError; end

  class ServerError < BraintreeError; end

  class ServiceUnavailableError < BraintreeError; end

  class SSLCertificateError < BraintreeError; end

  class TooManyRequestsError < BraintreeError; end

  class UnexpectedError < BraintreeError; end

  class UpgradeRequiredError < BraintreeError; end

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

  class TestOperationPerformedInProduction < BraintreeError; end
end

