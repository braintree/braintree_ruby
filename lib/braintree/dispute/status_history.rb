module Braintree
  class Dispute
    class StatusHistory # :nodoc:
      include BaseModule

      attr_reader :disbursement_date
      attr_reader :effective_date
      attr_reader :status
      attr_reader :timestamp

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
        @disbursement_date = Date.parse(disbursement_date) unless disbursement_date.nil?
        @effective_date = Date.parse(effective_date) unless effective_date.nil?
      end
    end
  end
end
