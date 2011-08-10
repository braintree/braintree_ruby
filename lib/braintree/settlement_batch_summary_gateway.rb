module Braintree
  class SettlementBatchSummaryGateway # :nodoc
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def generate(criteria)
      Util.verify_keys(SettlementBatchSummary._signature, criteria)
      response = @config.http.get "/settlement_batch_summary?#{Util.hash_to_query_string(criteria)}"
      SettlementBatchSummary._new(@gateway, response[:settlement_batch_summary])
    end
  end
end
