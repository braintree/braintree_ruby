module Braintree
  class AccountUpdaterDailyReport
    include BaseModule

    attr_reader :report_date
    attr_reader :report_url

    class << self
      protected :new
      def _new(*args)
        self.new(*args)
      end
    end

    def initialize(attributes)
      set_instance_variables_from_hash(attributes)
      @report_date = Date.parse(report_date)
    end
  end
end
