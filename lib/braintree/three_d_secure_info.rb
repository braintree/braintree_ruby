module Braintree
  class ThreeDSecureInfo # :nodoc:
    include BaseModule

    attr_reader :acs_transaction_id
    attr_reader :cavv
    attr_reader :ds_transaction_id
    attr_reader :eci_flag
    attr_reader :enrolled
    attr_reader :liability_shift_possible
    attr_reader :liability_shifted
    attr_reader :pares_status
    attr_reader :status
    attr_reader :three_d_secure_authentication_id
    attr_reader :three_d_secure_transaction_id
    attr_reader :three_d_secure_version
    attr_reader :xid
    attr_reader :lookup
    attr_reader :authentication

    alias_method :liability_shifted?, :liability_shifted
    alias_method :liability_shift_possible?, :liability_shift_possible

    def initialize(attributes)
      set_instance_variables_from_hash attributes unless attributes.nil?
    end

    def inspect
      attr_order = [
        :acs_transaction_id,
        :authentication,
        :cavv,
        :ds_transaction_id,
        :eci_flag,
        :enrolled,
        :liability_shift_possible,
        :liability_shifted,
        :lookup,
        :pares_status,
        :status,
        :three_d_secure_authentication_id,
        :three_d_secure_transaction_id,
        :three_d_secure_version,
        :xid
      ]

      formatted_attrs = attr_order.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<ThreeDSecureInfo #{formatted_attrs.join(", ")}>"
    end
  end
end
