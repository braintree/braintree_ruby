module Braintree
  # == More Information
  #
  # For more detailed documentation on Customers, see http://www.braintreepaymentsolutions.com/gateway/customer-api
  class Customer
    include BaseModule

    attr_reader :addresses, :company, :created_at, :credit_cards, :email, :fax, :first_name, :id, :last_name,
      :phone, :updated_at, :website, :custom_fields

    # Returns a ResourceCollection of all customers stored in the vault.
    #
    #   customers = Braintree::Customer.all
    #   customers.each do |customer|
    #     puts "Customer #{customer.id} email is #{customer.email}"
    #   end
    def self.all
      response = Http.post "/customers/advanced_search_ids"
      ResourceCollection.new(response) { |ids| _fetch_customers(ids) }
    end

    def self._fetch_customers(ids)
      response = Http.post "/customers/advanced_search", {:search => {:ids => ids}}
      attributes = response[:customers]
      Util.extract_attribute_as_array(attributes, :customer).map { |attrs| _new(attrs) }
    end

    # Creates a customer using the given +attributes+. If <tt>:id</tt> is not passed,
    # the gateway will generate it.
    #
    #   result = Braintree::Customer.create(
    #     :first_name => "John",
    #     :last_name => "Smith",
    #     :company => "Smith Co.",
    #     :email => "john@smith.com",
    #     :website => "www.smithco.com",
    #     :fax => "419-555-1234",
    #     :phone => "614-555-1234"
    #   )
    #   if result.success?
    #     puts "Created customer #{result.customer.id}
    #   else
    #     puts "Could not create customer, see result.errors"
    #   end
    def self.create(attributes = {})
      Util.verify_keys(_create_signature, attributes)
      _do_create "/customers", :customer => attributes
    end

    def self.create!(attributes = {})
      return_object_or_raise(:customer) { create(attributes) }
    end

    def self.create_customer_url
      "#{Braintree::Configuration.base_merchant_url}/customers/all/create_via_transparent_redirect_request"
    end

    def self.create_from_transparent_redirect(query_string)
      params = TransparentRedirect.parse_and_validate_query_string query_string
      _do_create("/customers/all/confirm_transparent_redirect_request", :id => params[:id])
    end

    def self.create_customer_transparent_redirect_url
      "#{Braintree::Configuration.base_merchant_url}/customers"
    end

    def self.credit(customer_id, transaction_attributes)
      Transaction.credit(transaction_attributes.merge(:customer_id => customer_id))
    end

    def self.credit!(customer_id, transaction_attributes)
       return_object_or_raise(:transaction){ credit(customer_id, transaction_attributes) }
    end

    def self.delete(customer_id)
      Http.delete("/customers/#{customer_id}")
      SuccessfulResult.new
    end

    def self.find(customer_id)
      raise ArgumentError, "customer_id contains invalid characters" unless customer_id.to_s =~ /\A[\w-]+\z/
      raise ArgumentError, "customer_id cannot be blank" if customer_id.to_s == ""
      response = Http.get("/customers/#{customer_id}")
      new(response[:customer])
    rescue NotFoundError
      raise NotFoundError, "customer with id #{customer_id.inspect} not found"
    end

    def self.sale(customer_id, transaction_attributes)
      Transaction.sale(transaction_attributes.merge(:customer_id => customer_id))
    end

    def self.sale!(customer_id, transaction_attributes)
       return_object_or_raise(:transaction){ sale(customer_id, transaction_attributes) }
    end

    # Returns a ResourceCollection of transactions for the customer with the given +customer_id+.
    def self.transactions(customer_id, options = {})
      response = Http.post "/customers/#{customer_id}/transaction_ids"
      ResourceCollection.new(response) { |ids| _fetch_transactions(customer_id, ids) }
    end

    def self._fetch_transactions(customer_id, ids)
      response = Http.post "/customers/#{customer_id}/transactions", :search => {:ids => ids}
      attributes = response[:credit_card_transactions]
      Util.extract_attribute_as_array(attributes, :transaction).map do |transaction_attributes|
        Transaction._new transaction_attributes
      end
    end

    def self.update(customer_id, attributes)
      Util.verify_keys(_update_signature, attributes)
      _do_update(:put, "/customers/#{customer_id}", :customer => attributes)
    end

    def self.update!(customer_id, attributes)
      return_object_or_raise(:customer) { update(customer_id, attributes) }
    end

    def self.update_customer_url
      "#{Braintree::Configuration.base_merchant_url}/customers/all/update_via_transparent_redirect_request"
    end

    def self.update_from_transparent_redirect(query_string)
      params = TransparentRedirect.parse_and_validate_query_string(query_string)
      _do_update(:post, "/customers/all/confirm_transparent_redirect_request", :id => params[:id])
    end

    def initialize(attributes) # :nodoc:
      set_instance_variables_from_hash(attributes)
      @credit_cards = (@credit_cards || []).map { |pm| CreditCard._new pm }
      @addresses = (@addresses || []).map { |addr| Address._new addr }
    end

    def credit(transaction_attributes)
      Customer.credit(id, transaction_attributes)
    end

    def credit!(transaction_attributes)
      return_object_or_raise(:transaction) { credit(transaction_attributes) }
    end

    def delete
      Customer.delete(id)
    end

    def inspect # :nodoc:
      first = [:id]
      last = [:addresses, :credit_cards]
      order = first + (self.class._attributes - first - last) + last
      nice_attributes = order.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<#{self.class} #{nice_attributes.join(', ')}>"
    end

    def sale(transaction_attributes)
      Customer.sale(id, transaction_attributes)
    end

    def sale!(transaction_attributes)
      return_object_or_raise(:transaction) { sale(transaction_attributes) }
    end

    # Returns a ResourceCollection of transactions for the customer.
    def transactions(options = {})
      Customer.transactions(id, options)
    end

    def update(attributes)
      response = Http.put "/customers/#{id}", :customer => attributes
      if response[:customer]
        set_instance_variables_from_hash response[:customer]
        SuccessfulResult.new(:customer => self)
      elsif response[:api_error_response]
        ErrorResult.new(response[:api_error_response])
      else
        raise "expected :customer or :errors"
      end
    end

    def update!(attributes)
      return_object_or_raise(:customer) { update(attributes) }
    end

    def ==(other)
      return false unless other.is_a?(Customer)
      id == other.id
    end

    class << self
      protected :new
    end

    def self._attributes # :nodoc:
      [
        :addresses, :company, :credit_cards, :email, :fax, :first_name, :id, :last_name, :phone, :website,
        :created_at, :updated_at
      ]
    end

    def self._create_signature # :nodoc:
      credit_card_signature = CreditCard._create_signature - [:customer_id]
      [
        :company, :email, :fax, :first_name, :id, :last_name, :phone, :website,
        {:credit_card => credit_card_signature},
        {:custom_fields => :_any_key_}
      ]
    end

    def self._do_create(url, params) # :nodoc:
      response = Http.post url, params
      if response[:customer]
        SuccessfulResult.new(:customer => new(response[:customer]))
      elsif response[:api_error_response]
        ErrorResult.new(response[:api_error_response])
      else
        raise "expected :customer or :api_error_response"
      end
    end

    def self._do_update(http_verb, url, params) # :nodoc:
      response = Http.send http_verb, url, params
      if response[:customer]
        SuccessfulResult.new(:customer => new(response[:customer]))
      elsif response[:api_error_response]
        ErrorResult.new(response[:api_error_response])
      else
        raise UnexpectedError, "expected :customer or :api_error_response"
      end
    end

    def self._new(*args) # :nodoc:
      self.new *args
    end

    def self._update_signature # :nodoc:
      [ :company, :email, :fax, :first_name, :id, :last_name, :phone, :website, {:custom_fields => :_any_key_} ]
    end
  end
end
