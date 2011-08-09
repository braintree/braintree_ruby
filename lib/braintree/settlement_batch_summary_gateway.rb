module Braintree
  class SettlementBatchSummaryGateway # :nodoc
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def generate(settlement_date)
      criteria = { :settlement_date => settlement_date }
      response = @config.http.get "/settlement_batch_summary?#{Util.hash_to_query_string(criteria)}"
      SettlementBatchSummary._new(@gateway, response)
    end
  end
end
