module Braintree
  class MerchantAccount
    include BaseModule

    module Status
      Pending = "pending"
      Active = "active"
      Suspended = "suspended"
    end

    module FundingDestination
      Bank = "bank"
      MobilePhone = "mobile_phone"
      Email = "email"
    end

    module FundingDestinations
      include Braintree::MerchantAccount::FundingDestination
    end

    attr_reader :status, :id, :master_merchant_account,
      :individual_details, :business_details, :funding_details,
      :currency_iso_code, :default

    def self.create(attributes)
      Configuration.gateway.merchant_account.create(attributes)
    end

    def self.find(attributes)
      Configuration.gateway.merchant_account.find(attributes)
    end

    def self.update(id, attributes)
      Configuration.gateway.merchant_account.update(id, attributes)
    end

    def initialize(gateway, attributes) # :nodoc
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @individual_details = IndividualDetails.new(@individual)
      @business_details = BusinessDetails.new(@business)
      @funding_details = FundingDetails.new(@funding)
      @master_merchant_account = MerchantAccount._new(@gateway, attributes.delete(:master_merchant_account)) if attributes[:master_merchant_account]
    end

    class << self
      protected :new
      def _new(*args) # :nodoc:
        self.new *args
      end
    end

    def inspect
      order = [:id, :status, :master_merchant_account]
      nice_attributes = order.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<#{self.class}: #{nice_attributes.join(', ')}>"
    end
  end
end
