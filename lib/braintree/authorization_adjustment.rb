module Braintree
  class AuthorizationAdjustment # :nodoc:
    include BaseModule

    attr_reader :amount, :success, :timestamp

    class << self
      protected :new
      def _new(*args) # :nodoc:
        self.new *args
      end
    end

    def initialize(attributes) # :nodoc:
      set_instance_variables_from_hash(attributes)
    end
  end
end
