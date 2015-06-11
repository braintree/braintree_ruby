module Braintree
  class TestingGateway # :nodoc:

    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
      @transaction_gateway = TransactionGateway.new(gateway)
    end

    def settle(transaction_id)
      check_environment

      response = @config.http.put("#{@config.base_merchant_path}/transactions/#{transaction_id}/settle")
      @transaction_gateway._handle_transaction_response(response)
    end

    def settlement_confirm(transaction_id)
      check_environment

      response = @config.http.put("#{@config.base_merchant_path}/transactions/#{transaction_id}/settlement_confirm")
      @transaction_gateway._handle_transaction_response(response)
    end

    def settlement_decline(transaction_id)
      check_environment

      response = @config.http.put("#{@config.base_merchant_path}/transactions/#{transaction_id}/settlement_decline")
      @transaction_gateway._handle_transaction_response(response)
    end

    def settlement_pending(transaction_id)
      check_environment

      response = @config.http.put("#{@config.base_merchant_path}/transactions/#{transaction_id}/settlement_pending")
      @transaction_gateway._handle_transaction_response(response)
    end

    def check_environment
      raise TestOperationPerformedInProduction if Braintree::Configuration.environment == :production
    end
  end
end
