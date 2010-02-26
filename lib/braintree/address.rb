module Braintree
  # An Address belongs to a Customer. It can be associated to a
  # CreditCard as the billing address. It can also be used
  # as the shipping address when creating a Transaction.
  class Address
    include BaseModule # :nodoc:

    attr_reader :company, :country_name, :created_at, :customer_id, :extended_address, :first_name, :id,
      :last_name, :locality, :postal_code, :region, :street_address, :updated_at

    def self.create(attributes)
      Util.verify_keys(_create_signature, attributes)
      unless attributes[:customer_id]
        raise ArgumentError, "Expected hash to contain a :customer_id"
      end
      unless attributes[:customer_id] =~ /\A[0-9A-Za-z_-]+\z/
        raise ArgumentError, ":customer_id contains invalid characters"
      end
      response = Http.post "/customers/#{attributes.delete(:customer_id)}/addresses", :address => attributes
      if response[:address]
        SuccessfulResult.new(:address => new(response[:address]))
      elsif response[:api_error_response]
        ErrorResult.new(response[:api_error_response])
      else
        raise UnexpectedError, "expected :address or :api_error_response"
      end
    end

    def self.create!(attributes)
      return_object_or_raise(:address) { create(attributes) }
    end

    def self.delete(customer_or_customer_id, address_id)
      customer_id = _determine_customer_id(customer_or_customer_id)
      Http.delete("/customers/#{customer_id}/addresses/#{address_id}")
      SuccessfulResult.new
    end

    # Finds the address with the given +address_id+ that is associated to the given +customer_or_customer_id+.
    # If the address cannot be found, a NotFoundError will be raised.
    def self.find(customer_or_customer_id, address_id)
      customer_id = _determine_customer_id(customer_or_customer_id)
      response = Http.get("/customers/#{customer_id}/addresses/#{address_id}")
      new(response[:address])
    rescue NotFoundError
      raise NotFoundError, "address for customer #{customer_id.inspect} with id #{address_id.inspect} not found"
    end

    def self.update(customer_or_customer_id, address_id, attributes)
      Util.verify_keys(_update_signature, attributes)
      customer_id = _determine_customer_id(customer_or_customer_id)
      response = Http.put "/customers/#{customer_id}/addresses/#{address_id}", :address => attributes
      if response[:address]
        SuccessfulResult.new(:address => new(response[:address]))
      elsif response[:api_error_response]
        ErrorResult.new(response[:api_error_response])
      else
        raise UnexpectedError, "expected :address or :api_error_response"
      end
    end

    def self.update!(customer_or_customer_id, address_id, attributes)
      return_object_or_raise(:address) { update(customer_or_customer_id, address_id, attributes) }
    end

    def initialize(attributes) # :nodoc:
      set_instance_variables_from_hash(attributes)
    end

    def ==(other) # :nodoc:
      return false unless other.is_a?(Address)
      id == other.id && customer_id == other.customer_id
    end

    # Deletes the address.
    def delete
      Address.delete(customer_id, self.id)
    end

    def update(attributes)
      Util.verify_keys(self.class._update_signature, attributes)
      response = Http.put "/customers/#{customer_id}/addresses/#{id}", :address => attributes
      if response[:address]
        set_instance_variables_from_hash response[:address]
        SuccessfulResult.new(:address => self)
      elsif response[:api_error_response]
        ErrorResult.new(response[:api_error_response])
      else
        raise UnexpectedError, "expected :address or :api_error_response"
      end
    end

    def update!(attributes)
      return_object_or_raise(:address) { update(attributes) }
    end

    class << self
      protected :new
    end

    def self._create_signature # :nodoc:
      [:company, :country_name, :customer_id, :extended_address, :first_name,
        :last_name, :locality, :postal_code, :region, :street_address]
    end

    def self._determine_customer_id(customer_or_customer_id) # :nodoc:
      customer_id = customer_or_customer_id.is_a?(Customer) ? customer_or_customer_id.id : customer_or_customer_id
      unless customer_id =~ /\A[\w_-]+\z/
        raise ArgumentError, "customer_id contains invalid characters"
      end
      customer_id
    end

    def self._new(*args) # :nodoc:
      self.new *args
    end

    def self._update_signature # :nodoc:
      _create_signature
    end
  end
end
