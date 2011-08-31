module Braintree
  # See http://www.braintreepayments.com/docs/ruby/general/result_objects
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
      "#<#{self.class} #{inspected_attributes.join(" ")}>"
    end

    def success?
      true
    end
  end
end
