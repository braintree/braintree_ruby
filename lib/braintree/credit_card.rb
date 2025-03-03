module Braintree
  class CreditCard
    include BaseModule
    include Braintree::Util::TokenEquality

    module CardType
      AmEx = "American Express"
      CarteBlanche = "Carte Blanche"
      ChinaUnionPay = "China UnionPay"
      DinersClubInternational = "Diners Club"
      Discover = "Discover"
      Elo = "Elo"
      JCB = "JCB"
      Laser = "Laser"
      UK_Maestro = "UK Maestro"
      Maestro = "Maestro"
      MasterCard = "MasterCard"
      Solo = "Solo"
      Switch = "Switch"
      Visa = "Visa"
      Unknown = "Unknown"

      All = constants.map { |c| const_get(c) }
    end

    module DebitNetwork
      Accel = "ACCEL"
      Maestro = "MAESTRO"
      Nyce = "NYCE"
      Pulse = "PULSE"
      Star = "STAR"
      Star_Access = "STAR_ACCESS"

      All = constants.map { |c| const_get(c) }
    end

    module CustomerLocation
      International = "international"
      US = "us"
    end

    module CardTypeIndicator
      Yes = "Yes"
      No = "No"
      Unknown = "Unknown"
    end

    Commercial = CountryOfIssuance = Debit = DurbinRegulated = Healthcare =
      IssuingBank = Payroll = Prepaid = PrepaidReloadable = ProductId = CardTypeIndicator

    attr_reader :billing_address
    attr_reader :bin
    attr_reader :card_type
    attr_reader :cardholder_name
    attr_reader :commercial
    attr_reader :country_of_issuance
    attr_reader :created_at
    attr_reader :customer_id
    attr_reader :debit
    attr_reader :durbin_regulated
    attr_reader :expiration_month
    attr_reader :expiration_year
    attr_reader :healthcare
    attr_reader :image_url
    attr_reader :issuing_bank
    attr_reader :last_4
    attr_reader :payroll
    attr_reader :prepaid
    attr_reader :prepaid_reloadable
    attr_reader :product_id
    attr_reader :subscriptions
    attr_reader :token
    attr_reader :unique_number_identifier
    attr_reader :updated_at
    attr_reader :verification

    def self.create(*args)
      Configuration.gateway.credit_card.create(*args)
    end

    def self.create!(*args)
      Configuration.gateway.credit_card.create!(*args)
    end

    # NEXT_MAJOR_VERSION remove this method
    # CreditCard.credit has been deprecated in favor of Transaction.credit
    def self.credit(token, transaction_attributes)
      warn "[DEPRECATED] CreditCard.credit is deprecated. Use Transaction.credit instead"
      Transaction.credit(transaction_attributes.merge(:payment_method_token => token))
    end

    # NEXT_MAJOR_VERSION remove this method
    # CreditCard.credit has been deprecated in favor of Transaction.credit
    def self.credit!(token, transaction_attributes)
      warn "[DEPRECATED] CreditCard.credit is deprecated. Use Transaction.credit instead"
      return_object_or_raise(:transaction) { credit(token, transaction_attributes) }
    end

    def self.delete(*args)
      Configuration.gateway.credit_card.delete(*args)
    end

    def self.expired(*args)
      Configuration.gateway.credit_card.expired(*args)
    end

    def self.expiring_between(*args)
      Configuration.gateway.credit_card.expiring_between(*args)
    end

    def self.find(*args)
      Configuration.gateway.credit_card.find(*args)
    end

    def self.from_nonce(*args)
      Configuration.gateway.credit_card.from_nonce(*args)
    end

    # NEXT_MAJOR_VERSION remove this method
    # CreditCard.sale has been deprecated in favor of Transaction.sale
    def self.sale(token, transaction_attributes)
      warn "[DEPRECATED] CreditCard.sale is deprecated. Use Transaction.sale instead"
      Configuration.gateway.transaction.sale(transaction_attributes.merge(:payment_method_token => token))
    end

    # NEXT_MAJOR_VERSION remove this method
    # CreditCard.sale has been deprecated in favor of Transaction.sale
    def self.sale!(token, transaction_attributes)
      warn "[DEPRECATED] CreditCard.sale is deprecated. Use Transaction.sale instead"
      return_object_or_raise(:transaction) { sale(token, transaction_attributes) }
    end

    def self.update(*args)
      Configuration.gateway.credit_card.update(*args)
    end

    def self.update!(*args)
      Configuration.gateway.credit_card.update!(*args)
    end

    def initialize(gateway, attributes)
      @gateway = gateway
      set_instance_variables_from_hash(attributes)
      @billing_address = attributes[:billing_address] ? Address._new(@gateway, attributes[:billing_address]) : nil
      @subscriptions = (@subscriptions || []).map { |subscription_hash| Subscription._new(@gateway, subscription_hash) }
      @verification = _most_recent_verification(attributes)
    end

    def _most_recent_verification(attributes)
      sorted_verifications = (attributes[:verifications] || []).sort_by { |verification| verification[:created_at] }.reverse.first
      CreditCardVerification._new(sorted_verifications) if sorted_verifications
    end

    def default?
      @default
    end

    # Expiration date formatted as MM/YYYY
    def expiration_date
      "#{expiration_month}/#{expiration_year}"
    end

    def expired?
      @expired
    end

    def inspect
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

    def nonce
      @nonce ||= PaymentMethodNonce.create(token)
    end

    # NEXT_MAJOR_VERSION can this be removed? Venmo SDK integration is no more
    # Returns true if the card is associated with Venmo SDK
    # NEXT_MAJOR_VERSION Remove this method
    # The old venmo SDK class has been deprecated
    def venmo_sdk?
      warn "[DEPRECATED] The Venmo SDK integration is Unsupported. Please update your integration to use Pay with Venmo instead."
      @venmo_sdk
    end

    def is_network_tokenized?
      @is_network_tokenized
    end

    class << self
      protected :new
    end

    def self._attributes
      [
        :billing_address, :bin, :card_type, :cardholder_name, :commercial, :country_of_issuance, :created_at, :customer_id,
        :debit, :durbin_regulated, :expiration_month, :expiration_year, :healthcare, :image_url, :is_network_tokenized?,
        :issuing_bank, :last_4, :payroll, :prepaid, :prepaid_reloadable, :product_id, :token, :updated_at
      ]
    end

    def self._new(*args)
      self.new(*args)
    end
  end
end
