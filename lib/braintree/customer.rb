module Braintree
  # See http://www.braintreepaymentsolutions.com/docs/ruby
  class Customer
    include BaseModule

    attr_reader :addresses, :company, :created_at, :credit_cards, :email, :fax, :first_name, :id, :last_name,
      :phone, :updated_at, :website, :custom_fields

    # See http://www.braintreepaymentsolutions.com/docs/ruby/customers/search
    def self.all
      response = Http.post "/customers/advanced_search_ids"
      ResourceCollection.new(response) { |ids| _fetch_customers(ids) }
    end

    def self._fetch_customers(ids) # :nodoc:
      response = Http.post "/customers/advanced_search", {:search => {:ids => ids}}
      attributes = response[:customers]
      Util.extract_attribute_as_array(attributes, :customer).map { |attrs| _new(attrs) }
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/customers/create
    def self.create(attributes = {})
      Util.verify_keys(_create_signature, attributes)
      _do_create "/customers", :customer => attributes
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/customers/create
    def self.create!(attributes = {})
      return_object_or_raise(:customer) { create(attributes) }
    end

    # Deprecated. Use Braintree::TransparentRedirect.url
    #
    # See http://www.braintreepaymentsolutions.com/docs/ruby/customers/create_tr
    def self.create_customer_url
      warn "[DEPRECATED] Customer.create_customer_url is deprecated. Please use TransparentRedirect.url"
      "#{Braintree::Configuration.base_merchant_url}/customers/all/create_via_transparent_redirect_request"
    end

    # Deprecated. Use Braintree::TransparentRedirect.confirm
    #
    # See http://www.braintreepaymentsolutions.com/docs/ruby/customers/create_tr
    def self.create_from_transparent_redirect(query_string)
      warn "[DEPRECATED] Customer.create_from_transparent_redirect is deprecated. Please use TransparentRedirect.confirm"
      params = TransparentRedirect.parse_and_validate_query_string query_string
      _do_create("/customers/all/confirm_transparent_redirect_request", :id => params[:id])
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_from_vault
    def self.credit(customer_id, transaction_attributes)
      Transaction.credit(transaction_attributes.merge(:customer_id => customer_id))
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_from_vault
    def self.credit!(customer_id, transaction_attributes)
       return_object_or_raise(:transaction){ credit(customer_id, transaction_attributes) }
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/customers/delete
    def self.delete(customer_id)
      Http.delete("/customers/#{customer_id}")
      SuccessfulResult.new
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/customers/search
    def self.find(customer_id)
      raise ArgumentError, "customer_id contains invalid characters" unless customer_id.to_s =~ /\A[\w-]+\z/
      raise ArgumentError, "customer_id cannot be blank" if customer_id.to_s == ""
      response = Http.get("/customers/#{customer_id}")
      new(response[:customer])
    rescue NotFoundError
      raise NotFoundError, "customer with id #{customer_id.inspect} not found"
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_from_vault
    def self.sale(customer_id, transaction_attributes)
      Transaction.sale(transaction_attributes.merge(:customer_id => customer_id))
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_from_vault
    def self.sale!(customer_id, transaction_attributes)
       return_object_or_raise(:transaction){ sale(customer_id, transaction_attributes) }
    end

    # Returns a ResourceCollection of transactions for the customer with the given +customer_id+.
    def self.transactions(customer_id, options = {})
      response = Http.post "/customers/#{customer_id}/transaction_ids"
      ResourceCollection.new(response) { |ids| _fetch_transactions(customer_id, ids) }
    end

    def self._fetch_transactions(customer_id, ids) # :nodoc:
      response = Http.post "/customers/#{customer_id}/transactions", :search => {:ids => ids}
      attributes = response[:credit_card_transactions]
      Util.extract_attribute_as_array(attributes, :transaction).map do |transaction_attributes|
        Transaction._new transaction_attributes
      end
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/customers/update
    def self.update(customer_id, attributes)
      Util.verify_keys(_update_signature, attributes)
      _do_update(:put, "/customers/#{customer_id}", :customer => attributes)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/customers/update
    def self.update!(customer_id, attributes)
      return_object_or_raise(:customer) { update(customer_id, attributes) }
    end

    # Deprecated. Use Braintree::TransparentRedirect.url
    #
    # See http://www.braintreepaymentsolutions.com/docs/ruby/customers/update_tr
    def self.update_customer_url
      warn "[DEPRECATED] Customer.update_customer_url is deprecated. Please use TransparentRedirect.url"
      "#{Braintree::Configuration.base_merchant_url}/customers/all/update_via_transparent_redirect_request"
    end

    # Deprecated. Use Braintree::TransparentRedirect.confirm
    #
    # See http://www.braintreepaymentsolutions.com/docs/ruby/customers/update_tr
    def self.update_from_transparent_redirect(query_string)
      warn "[DEPRECATED] Customer.update_from_transparent_redirect is deprecated. Please use TransparentRedirect.confirm"
      params = TransparentRedirect.parse_and_validate_query_string(query_string)
      _do_update(:post, "/customers/all/confirm_transparent_redirect_request", :id => params[:id])
    end

    def initialize(attributes) # :nodoc:
      set_instance_variables_from_hash(attributes)
      @credit_cards = (@credit_cards || []).map { |pm| CreditCard._new pm }
      @addresses = (@addresses || []).map { |addr| Address._new addr }
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_from_vault
    def credit(transaction_attributes)
      Customer.credit(id, transaction_attributes)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_from_vault
    def credit!(transaction_attributes)
      return_object_or_raise(:transaction) { credit(transaction_attributes) }
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/customers/delete
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

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_from_vault
    def sale(transaction_attributes)
      Customer.sale(id, transaction_attributes)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/transactions/create_from_vault
    def sale!(transaction_attributes)
      return_object_or_raise(:transaction) { sale(transaction_attributes) }
    end

    # Returns a ResourceCollection of transactions for the customer.
    def transactions(options = {})
      Customer.transactions(id, options)
    end

    # See http://www.braintreepaymentsolutions.com/docs/ruby/customers/update
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

    # See http://www.braintreepaymentsolutions.com/docs/ruby/customers/update
    def update!(attributes)
      return_object_or_raise(:customer) { update(attributes) }
    end

    # Returns true if +other+ is a Customer with the same id
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

    def self._do_create(url, params=nil) # :nodoc:
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
      credit_card_signature = CreditCard._update_signature - [:customer_id]
      credit_card_options = credit_card_signature.find { |item| item.respond_to?(:keys) && item.keys == [:options] }
      credit_card_options[:options] << :update_existing_token
      [
        :company, :email, :fax, :first_name, :id, :last_name, :phone, :website,
        {:credit_card => credit_card_signature},
        {:custom_fields => :_any_key_}
      ]
    end
  end
end
