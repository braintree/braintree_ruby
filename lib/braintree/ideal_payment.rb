module Braintree
  class IdealPayment
    include BaseModule

    attr_reader :id, :ideal_transaction_id, :currency, :amount, :status, :order_id, :issuer, :approval_url, :iban_bank_account

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @iban_bank_account = IbanBankAccount.new(attributes[:iban_bank_account])
    end

    class << self
      protected :new
    end

    def self._new(*args) # :nodoc:
      self.new *args
    end

    def self.sale(ideal_payment_id, transaction_attributes)
      Configuration.gateway.transaction.sale(transaction_attributes.merge(
            :payment_method_nonce => ideal_payment_id,
            :options => { :submit_for_settlement => true }
          )
        )
    end

    def self.sale!(ideal_payment_id, transaction_attributes)
      return_object_or_raise(:transaction) { sale(ideal_payment_id, transaction_attributes) }
    end

    def self.find(ideal_payment_id)
      Configuration.gateway.ideal_payment.find(ideal_payment_id)
    end

    class IbanBankAccount
      include BaseModule
      attr_reader :account_holder_name, :bic, :masked_iban, :iban_account_number_last_4, :iban_country, :description

      def initialize(attributes) # :nodoc:
        set_instance_variables_from_hash(attributes)
      end
    end
  end
end
