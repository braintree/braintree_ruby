module Braintree
  class TestingGateway # :nodoc:

    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
      @transaction_gateway = TransactionGateway.new(gateway)
    end

    def settle(transaction_id)
      response = @config.http.put "/transactions/#{transaction_id}/settle"
      @transaction_gateway._handle_transaction_response(response)
    end

    def settlement_confirm(transaction_id)
      response = @config.http.put "/transactions/#{transaction_id}/settlement_confirm"
      @transaction_gateway._handle_transaction_response(response)
    end

    def settlement_decline(transaction_id)
      response = @config.http.put "/transactions/#{transaction_id}/settlement_decline"
      @transaction_gateway._handle_transaction_response(response)
    end

  end
end
