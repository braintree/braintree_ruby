module Braintree
  class EnrichedCustomerData
    include BaseModule

    attr_reader :fields_updated
    attr_reader :profile_data

    def initialize(attributes)
      set_instance_variables_from_hash(attributes)
      @profile_data = VenmoProfileData._new(attributes[:profile_data])
    end

    class << self
      protected :new
    end

    def self._new(*args)
      self.new(*args)
    end
  end
end
