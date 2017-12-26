module Braintree
  class Dispute
    class Evidence # :nodoc:
      include BaseModule

      attr_reader :comment, :created_at, :id, :sent_to_processor_at, :url

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
        @sent_to_processor_at = Date.parse(sent_to_processor_at) unless sent_to_processor_at.nil?
      end
    end
  end
end
