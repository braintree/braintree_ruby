module Braintree
  class IdealPayment
    include BaseModule

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
  end
end
