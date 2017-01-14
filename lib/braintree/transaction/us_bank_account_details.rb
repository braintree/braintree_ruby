module Braintree
  class Transaction
    class UsBankAccountDetails # :nodoc:
      include BaseModule

      attr_reader :routing_number, :last_4, :account_type, :account_holder_name, :token, :image_url, :bank_name, :ach_mandate

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
        @ach_mandate = attributes[:ach_mandate] ? AchMandate.new(attributes[:ach_mandate]) : nil
      end
    end
  end
end
