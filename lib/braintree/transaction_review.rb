module Braintree
  class TransactionReview
    include BaseModule

    attr_reader :transaction_id, :decision, :reviewer_email, :reviewer_note, :reviewer_time

    def initialize(attributes)
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
