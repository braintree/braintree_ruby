module Braintree
  class VenmoProfileData
    include BaseModule

    attr_reader :billing_address
    attr_reader :email
    attr_reader :first_name
    attr_reader :last_name
    attr_reader :phone_number
    attr_reader :shipping_address
    attr_reader :username

    def initialize(attributes)
      set_instance_variables_from_hash(attributes)
    end

    class << self
      protected :new
    end

    def self._new(*args)
      self.new(*args)
    end
  end
end
