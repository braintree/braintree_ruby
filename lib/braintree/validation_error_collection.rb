module Braintree
  # A collection of validation errors.
  #
  #   result = Braintree::Customer.create(
  #     :email => "invalid",
  #     :credit_card => {
  #       :number => "invalidnumber",
  #       :billing_address => {
  #         :country_name => "invalid"
  #       }
  #     }
  #   )
  #   result.success?
  #   #=> false
  #   result.errors.for(:customer).on(:email)
  #   #=> [#<Braintree::ValidationError (81604) Email is an invalid format.>]
  #   result.errors.for(:customer).for(:credit_card).on(:number)
  #   #=> [#<Braintree::ValidationError (81715) Credit card number is invalid.>]
  #   result.errors.for(:customer).for(:credit_card).for(:billing_address).on(:country_name)
  #   #=> [#<Braintree::ValidationError (91803) Country name is not an accepted country.>]
  #
  # == More Information
  #
  # For more detailed documentation on ValidationErrors, see http://www.braintreepaymentsolutions.com/gateway/validation-errors
  class ValidationErrorCollection
    include Enumerable

    def initialize(data) # :nodoc:
      @errors = data[:errors].map { |hash| Braintree::ValidationError.new(hash) }
      @nested = {}
      data.keys.each do |key|
        next if key == :errors
        @nested[key] = ValidationErrorCollection.new(data[key])
      end
    end

    # Accesses the error at the given index.
    def [](index)
      @errors[index]
    end

    # Returns an array of ValidationError objects at this level and all nested levels in the error
    # hierarchy
    def deep_errors
      ([@errors] + @nested.values.map { |error_collection| error_collection.deep_errors }).flatten
    end

    def deep_size
      size + @nested.values.inject(0) { |count, error_collection| count + error_collection.deep_size }
    end

    # Iterates over errors at the current level. Nested errors will not be yielded.
    def each(&block)
      @errors.each(&block)
    end

    # Returns a ValidationErrorCollection of errors nested under the given nested_key.
    # Returns nil if there are not any errors nested under the given key.
    def for(nested_key)
      nested_key = "index_#{nested_key}".to_sym if nested_key.is_a? Fixnum
      @nested[nested_key]
    end

    def inspect # :nodoc:
      "#<#{self.class} errors#{_inner_inspect}>"
    end

    # Returns an array of ValidationError objects on the given attribute.
    def on(attribute)
      @errors.select { |error| error.attribute == attribute.to_s }
    end

    # Returns an array of ValidationError objects at the given level in the error hierarchy
    def shallow_errors
      @errors.dup
    end

    # The number of errors at this level. This does not include nested errors.
    def size
      @errors.size
    end

    def _inner_inspect(scope = []) # :nodoc:
      all = []
      scope_string = scope.join("/")
      if @errors.any?
        all << "#{scope_string}:[" + @errors.map { |e| "(#{e.code}) #{e.message}" }.join(", ") + "]"
      end
      @nested.each do |key, values|
        all << values._inner_inspect(scope + [key])
      end
      all.join(", ")
    end
  end
end

