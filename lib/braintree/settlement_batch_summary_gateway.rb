module Braintree
  class SettlementBatchSummaryGateway # :nodoc
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def generate(criteria)
      Util.verify_keys(SettlementBatchSummary._signature, criteria)
      response = @config.http.get "/settlement_batch_summary?#{Util.hash_to_query_string(criteria)}"
      if response[:settlement_batch_summary]
        SuccessfulResult.new(:settlement_batch_summary => SettlementBatchSummary._new(@gateway, response[:settlement_batch_summary]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :settlement_batch_summary or :api_error_response"
      end
    end
  end
end
