module Braintree 
  # A SuccessfulResult will be returned from non-bang methods when
  # validations pass. It will provide access to the created resource.
  # For example, when creating a customer, SuccessfulResult will
  # respond to +customer+ like so:
  #
  #   result = Customer.create(:first_name => "John")
  #   if result.success?
  #     # have a SuccessfulResult
  #     puts "Created customer #{result.customer.id}
  #   else
  #     # have an ErrorResult
  #   end
  class SuccessfulResult
    include BaseModule
  
    def initialize(attributes = {}) # :nodoc:
      @attrs = attributes.keys
      singleton_class.class_eval do
        attributes.each do |key, value|
          define_method key do
            value
          end
        end
      end  
    end

    def inspect # :nodoc:
      inspected_attributes = @attrs.map { |attr| "#{attr}:#{send(attr).inspect}" }
      "#<#{self.class} #{inspected_attributes}>"
    end

    # Always returns true.
    def success?
      true
    end
  end
end
