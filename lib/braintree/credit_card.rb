module Braintree
  # == More Information
  #
  # For more detailed documentation on CreditCards, see http://www.braintreepaymentsolutions.com/gateway/credit-card-api
  # For more detailed documentation on CreditCard verification, see http://www.braintreepaymentsolutions.com/gateway/credit-card-verification-api
  class CreditCard
    include BaseModule # :nodoc:

    module CardType
      AmEx = "American Express"
      CarteBlanche = "Carte Blanche"
      ChinaUnionPay = "China UnionPay"
      DinersClubInternational = "Diners Club"
      Discover = "Discover"
      JCB = "JCB"
      Laser = "Laser"
      Maestro = "Maestro"
      MasterCard = "MasterCard"
      Solo = "Solo"
      Switch = "Switch"
      Visa = "Visa"
      Unknown = "Unknown"

      All = constants.map { |c| const_get(c) }
    end

    module CustomerLocation
      International = "international"
      US = "us"
    end

    attr_reader :billing_address, :bin, :card_type, :cardholder_name, :created_at, :customer_id, :expiration_month,
      :expiration_year, :last_4, :subscriptions, :token, :updated_at

    def self.create(attributes)
      if attributes.has_key?(:expiration_date) && (attributes.has_key?(:expiration_month) || attributes.has_key?(:expiration_year))
        raise ArgumentError.new("create with both expiration_month and expiration_year or only expiration_date")
      end
      Util.verify_keys(_create_signature, attributes)
      _do_create("/payment_methods", :credit_card => attributes)
    end

    def self.create!(attributes)
      return_object_or_raise(:credit_card) { create(attributes) }
    end

    # The transparent redirect URL to use to create a credit card.
    def self.create_credit_card_url
      "#{Braintree::Configuration.base_merchant_url}/payment_methods/all/create_via_transparent_redirect_request"
    end

    def self.create_from_transparent_redirect(query_string)
      params = TransparentRedirect.parse_and_validate_query_string query_string
      _do_create("/payment_methods/all/confirm_transparent_redirect_request", :id => params[:id])
    end

    def self.credit(token, transaction_attributes)
      Transaction.credit(transaction_attributes.merge(
        :payment_method_token => token
      ))
    end

    def self.credit!(token, transaction_attributes)
      return_object_or_raise(:transaction) { credit(token, transaction_attributes) }
    end

    # Returns a ResourceCollection of expired credit cards.
    def self.expired(options = {})
      response = Http.post("/payment_methods/all/expired_ids")
      ResourceCollection.new(response) { |ids| _fetch_expired(ids) }
    end

    # Returns a ResourceCollection of credit cards expiring between +start_date+ and +end_date+ inclusive.
    # Only the month and year of the start and end dates are used.
    def self.expiring_between(start_date, end_date, options = {})
      formatted_start_date = start_date.strftime('%m%Y')
      formatted_end_date = end_date.strftime('%m%Y')
      response = Http.post("/payment_methods/all/expiring_ids?start=#{formatted_start_date}&end=#{formatted_end_date}")
      ResourceCollection.new(response) { |ids| _fetch_expiring_between(formatted_start_date, formatted_end_date, ids) }
    end

    # Finds the credit card with the given +token+. Raises a NotFoundError if it cannot be found.
    def self.find(token)
      response = Http.get "/payment_methods/#{token}"
      new(response[:credit_card])
    rescue NotFoundError
      raise NotFoundError, "payment method with token #{token.inspect} not found"
    end

    def self.sale(token, transaction_attributes)
      Transaction.sale(transaction_attributes.merge(
        :payment_method_token => token
      ))
    end

    def self.sale!(token, transaction_attributes)
      return_object_or_raise(:transaction) { sale(token, transaction_attributes) }
    end

    def self.update(token, attributes)
      Util.verify_keys(_update_signature, attributes)
      _do_update(:put, "/payment_methods/#{token}", :credit_card => attributes)
    end

    def self.update!(token, attributes)
      return_object_or_raise(:credit_card) { update(token, attributes) }
    end

    def self.update_from_transparent_redirect(query_string)
      params = TransparentRedirect.parse_and_validate_query_string query_string
      _do_update(:post, "/payment_methods/all/confirm_transparent_redirect_request", :id => params[:id])
    end

    # The transparent redirect URL to use to update a credit card.
    def self.update_credit_card_url
      "#{Braintree::Configuration.base_merchant_url}/payment_methods/all/update_via_transparent_redirect_request"
    end

    def self._fetch_expired(ids)
      response = Http.post("/payment_methods/all/expired", :search => {:ids => ids})
      attributes = response[:payment_methods]
      Util.extract_attribute_as_array(attributes, :credit_card).map { |attrs| _new(attrs) }
    end

    def self._fetch_expiring_between(formatted_start_date, formatted_end_date, ids)
      response = Http.post(
        "/payment_methods/all/expiring?start=#{formatted_start_date}&end=#{formatted_end_date}",
        :search => {:ids => ids}
      )
      attributes = response[:payment_methods]
      Util.extract_attribute_as_array(attributes, :credit_card).map { |attrs| _new(attrs) }
    end

    def initialize(attributes) # :nodoc:
      _init attributes
      @subscriptions = (@subscriptions || []).map { |subscription_hash| Subscription._new(subscription_hash) }
    end

    # Creates a credit transaction for this credit card.
    def credit(transaction_attributes)
      Transaction.credit(transaction_attributes.merge(
        :payment_method_token => self.token
      ))
    end

    def credit!(transaction_attributes)
      return_object_or_raise(:transaction) { credit(transaction_attributes) }
    end

    def delete
      Http.delete("/payment_methods/#{token}")
    end

    # Returns true if this credit card is the customer's default.
    def default?
      @default
    end

    # Expiration date formatted as MM/YYYY
    def expiration_date
      "#{expiration_month}/#{expiration_year}"
    end

    # Returns true if the credit card is expired.
    def expired?
      @expired
    end

    def inspect # :nodoc:
      first = [:token]
      order = first + (self.class._attributes - first)
      nice_attributes = order.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<#{self.class} #{nice_attributes.join(', ')}>"
    end

    def masked_number
      "#{bin}******#{last_4}"
    end

    # Creates a sale transaction for this credit card.
    def sale(transaction_attributes)
      CreditCard.sale(self.token, transaction_attributes)
    end

    def sale!(transaction_attributes)
      return_object_or_raise(:transaction) { sale(transaction_attributes) }
    end

    def update(attributes)
      Util.verify_keys(self.class._update_signature, attributes)
      response = Http.put "/payment_methods/#{token}", :credit_card => attributes
      if response[:credit_card]
        _init response[:credit_card]
        SuccessfulResult.new(:credit_card => self)
      elsif response[:api_error_response]
        ErrorResult.new(response[:api_error_response])
      else
        raise UnexpectedError, "expected :credit_card or :api_error_response"
      end
    end

    def update!(attributes)
      return_object_or_raise(:credit_card) { update(attributes) }
    end

    # Returns true if +other+ is a +CreditCard+ with the same token.
    def ==(other)
      return false unless other.is_a?(CreditCard)
      token == other.token
    end

    class << self
      protected :new
    end

    def self._attributes # :nodoc:
      [
        :billing_address, :bin, :card_type, :cardholder_name, :created_at, :customer_id, :expiration_month,
        :expiration_year, :last_4, :token, :updated_at
      ]
    end

    def self._create_signature # :nodoc:
      _signature(:create)
    end

    def self._new(*args) # :nodoc:
      self.new *args
    end

    def self._do_create(url, params=nil) # :nodoc:
      response = Http.post url, params
      if response[:credit_card]
        SuccessfulResult.new(:credit_card => new(response[:credit_card]))
      elsif response[:api_error_response]
        ErrorResult.new(response[:api_error_response])
      else
        raise UnexpectedError, "expected :credit_card or :api_error_response"
      end
    end

    def self._do_update(http_verb, url, params) # :nodoc:
      response = Http.send http_verb, url, params
      if response[:credit_card]
        SuccessfulResult.new(:credit_card => new(response[:credit_card]))
      elsif response[:api_error_response]
        ErrorResult.new(response[:api_error_response])
      else
        raise UnexpectedError, "expected :credit_card or :api_error_response"
      end
    end

    def self._update_signature # :nodoc:
      _signature(:update)
    end

    def self._signature(type) # :nodoc:
      billing_address_params = [:company, :country_name, :extended_address, :first_name, :last_name, :locality, :postal_code, :region, :street_address]
      signature = [
        :cardholder_name, :cvv, :expiration_date, :expiration_month, :expiration_year, :number, :token,
        {:options => [:make_default, :verification_merchant_account_id, :verify_card]},
        {:billing_address => billing_address_params}
      ]

      case type
      when :create
        signature << :customer_id
      when :update
        billing_address_params << {:options => [:update_existing]}
      else
        raise ArgumentError
      end

      return signature
    end

    def _init(attributes) # :nodoc:
      set_instance_variables_from_hash(attributes)
      @billing_address = attributes[:billing_address] ? Address._new(attributes[:billing_address]) : nil
    end
  end
end
