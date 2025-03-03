module Braintree
  class BinData
    include BaseModule

    attr_reader :commercial
    attr_reader :country_of_issuance
    attr_reader :debit
    attr_reader :durbin_regulated
    attr_reader :healthcare
    attr_reader :issuing_bank
    attr_reader :payroll
    attr_reader :prepaid
    attr_reader :prepaid_reloadable
    attr_reader :product_id

    def initialize(attributes)
      set_instance_variables_from_hash attributes unless attributes.nil?
    end

    def inspect
      formatted_attributes = self.class._attributes.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<#{self.class} #{formatted_attributes.join(", ")}>"
    end

    def self._attributes
      [
        :commercial, :country_of_issuance, :debit, :durbin_regulated, :healthcare,
        :issuing_bank, :payroll, :prepaid, :prepaid_reloadable, :product_id
      ]
    end
  end
end
