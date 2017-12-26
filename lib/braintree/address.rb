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
    attr_reader :postal_code
    attr_reader :region
    attr_reader :street_address
    attr_reader :updated_at

    def self.create(attributes)
      Configuration.gateway.address.create(attributes)
    end

    def self.create!(attributes)
      return_object_or_raise(:address) { create(attributes) }
    end

    def self.delete(customer_or_customer_id, address_id)
      Configuration.gateway.address.delete(customer_or_customer_id, address_id)
    end

    def self.find(customer_or_customer_id, address_id)
      Configuration.gateway.address.find(customer_or_customer_id, address_id)
    end

    def self.update(customer_or_customer_id, address_id, attributes)
      Configuration.gateway.address.update(customer_or_customer_id, address_id, attributes)
    end

    def self.update!(customer_or_customer_id, address_id, attributes)
      return_object_or_raise(:address) { update(customer_or_customer_id, address_id, attributes) }
    end

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
    end

    def ==(other) # :nodoc:
      return false unless other.is_a?(Address)
      id == other.id && customer_id == other.customer_id
    end

    # Deprecated. Use Braintree::Address.delete
    def delete
      warn "[DEPRECATED] delete as an instance method is deprecated. Please use Address.delete"
      @gateway.address.delete(customer_id, self.id)
    end

    # Deprecated. Use Braintree::Address.update
    def update(attributes)
      warn "[DEPRECATED] update as an instance method is deprecated. Please use Address.update"
      result = @gateway.address.update(customer_id, id, attributes)
      if result.success?
        copy_instance_variables_from_object result.address
      end
      result
    end

    # Deprecated. Use Braintree::Address.update!
    def update!(attributes)
      warn "[DEPRECATED] update! as an instance method is deprecated. Please use Address.update!"
      return_object_or_raise(:address) { update(attributes) }
    end

    class << self
      protected :new
    end

    def self._new(*args) # :nodoc:
      self.new *args
    end
  end
end
