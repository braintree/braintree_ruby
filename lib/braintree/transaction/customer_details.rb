module Braintree
  class Transaction
    class CustomerDetails # :nodoc:
      include BaseModule
      
      attr_reader :company, :email, :fax, :first_name, :id, :last_name, :phone, :website

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
