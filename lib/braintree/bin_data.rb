module Braintree
  class BinData # :nodoc:
    include BaseModule

    attr_reader :commercial, :country_of_issuance, :debit, :durbin_regulated, :healthcare,
      :issuing_bank, :payroll, :prepaid, :product_id

    def initialize(attributes)
      set_instance_variables_from_hash attributes unless attributes.nil?
    end

    def inspect
      formatted_attrs = self.class._attributes.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<BinData #{formatted_attrs.join(", ")}>"
    end
  end
end
