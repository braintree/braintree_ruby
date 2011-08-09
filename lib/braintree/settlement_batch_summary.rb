module Braintree
  class SettlementBatchSummary
    include BaseModule
    attr_reader :records

    def self.generate(settlement_date)
      Configuration.gateway.settlement_batch_summary.generate(settlement_date)
    end

    def initialize(gateway, attributes)
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
    end

    class << self
      protected :new
      def _new(*args)
        self.new(*args)
      end
    end
  end
end
