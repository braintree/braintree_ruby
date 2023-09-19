module Braintree
  class Transaction
    class PaymentReceipt
      class CardPresentData
        include BaseModule

        attr_reader :application_cryptogram
        attr_reader :application_identifier
        attr_reader :application_interchange_profile
        attr_reader :application_name
        attr_reader :application_transaction_counter
        attr_reader :application_usage_control
        attr_reader :authorization_mode
        attr_reader :authorization_response_code
        attr_reader :card_entry_method
        attr_reader :card_sequence_number
        attr_reader :cardholder_verification_method_results
        attr_reader :cashback_amount
        attr_reader :cryptogram_information_data
        attr_reader :issuer_action_code_default
        attr_reader :issuer_action_code_denial
        attr_reader :issuer_action_code_online
        attr_reader :issuer_authentication_data
        attr_reader :terminal_country_code
        attr_reader :terminal_transaction_date
        attr_reader :terminal_transaction_type
        attr_reader :terminal_verification_result
        attr_reader :unpredictable_number

        def initialize(attributes)
          set_instance_variables_from_hash attributes unless attributes.nil?
        end
      end
    end
  end
end
