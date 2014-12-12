module Braintree
  class Transaction
    class SEPABankAccountDetails
      include BaseModule

      attr_reader :masked_iban, :bic, :account_holder_name, :mandate_reference_number, :mandate_accepted_at, :token, :image_url

      def initialize(attributes)
        set_instance_variables_from_hash attributes unless attributes.nil?
      end
    end
  end
end
