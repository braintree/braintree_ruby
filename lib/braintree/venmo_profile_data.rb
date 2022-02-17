module Braintree
  class VenmoProfileData
    include BaseModule

    attr_reader :username
    attr_reader :first_name
    attr_reader :last_name
    attr_reader :phone_number
    attr_reader :email

    def initialize(attributes) # :nodoc:
      set_instance_variables_from_hash(attributes)
    end

    class << self
      protected :new
    end

    def self._new(*args) # :nodoc:
      self.new(*args)
    end
  end
end
