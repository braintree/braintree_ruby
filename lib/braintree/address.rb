module Braintree
  class Address
    include BaseModule # :nodoc:

    attr_reader :company
    attr_reader :country_code_alpha2
    attr_reader :country_code_alpha3
    attr_reader :country_code_numeric
    attr_reader :country_name
    attr_reader :created_at
    attr_reader :customer_id
    attr_reader :extended_address
    attr_reader :first_name
    attr_reader :id
    attr_reader :last_name
    attr_reader :locality
    attr_reader :phone_number
    attr_reader :postal_code
    attr_reader :region
    attr_reader :street_address
    attr_reader :updated_at

    def self.create(*args)
      Configuration.gateway.address.create(*args)
    end

    def self.create!(*args)
      Configuration.gateway.address.create!(*args)
    end

    def self.delete(*args)
      Configuration.gateway.address.delete(*args)
    end

    def self.find(*args)
      Configuration.gateway.address.find(*args)
    end

    def self.update(*args)
      Configuration.gateway.address.update(*args)
    end

    def self.update!(*args)
      Configuration.gateway.address.update!(*args)
    end

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
    end

    def ==(other) # :nodoc:
      return false unless other.is_a?(Address)
      id == other.id && customer_id == other.customer_id
    end

    class << self
      protected :new
    end

    def self._new(*args) # :nodoc:
      self.new(*args)
    end
  end
end
