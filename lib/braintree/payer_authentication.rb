module Braintree
  class PayerAuthentication
    include BaseModule # :nodoc:

    attr_reader :id, :post_params, :post_url

    def initialize(gateway, attributes) # :nodoc:
      @gateway = gateway
      set_instance_variables_from_hash(attributes)

      @post_params = (@post_params || []).map do |params|
        OpenStruct.new(:name => params[:name], :value => params[:value])
      end
    end

    class << self
      protected :new
    end

    def self._new(*args) # :nodoc:
      self.new *args
    end
  end
end
