module Braintree
  class Descriptor # :nodoc:
    include BaseModule

    attr_reader :name, :phone

    def initialize(attributes)
      set_instance_variables_from_hash attributes unless attributes.nil?
    end
  end
end
