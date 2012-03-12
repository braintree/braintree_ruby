module Braintree
  class WebhookNotification
    include BaseModule

    class << self
      protected :new
      def _new(*args) # :nodoc:
        self.new *args
      end
    end

    attr_reader :subscription, :kind

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @subscription = Subscription._new(gateway, @subject[:subscription]) if @subject.has_key?(:subscription)
    end
  end
end
