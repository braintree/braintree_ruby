module Braintree
  class SettlementBatchSummaryGateway # :nodoc
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def generate(settlement_date, options)
      criteria = { :settlement_date => settlement_date }.merge(options)
      response = @config.http.get "/settlement_batch_summary?#{Util.hash_to_query_string(criteria)}"
      SettlementBatchSummary._new(@gateway, response[:settlement_batch_summary])
    end
  end
end
