module Braintree
    class MetaCheckoutCard
      include BaseModule # :nodoc:
      include Braintree::Util::TokenEquality

      attr_reader :bin
      attr_reader :business
      attr_reader :card_type
      attr_reader :cardholder_name
      attr_reader :commercial
      attr_reader :consumer
      attr_reader :container_id
      attr_reader :corporate
      attr_reader :country_of_issuance
      attr_reader :created_at
      attr_reader :customer_id
      attr_reader :customer_location
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
      attr_reader :purchase
      attr_reader :subscriptions
      attr_reader :token
      attr_reader :unique_number_identifier
      attr_reader :updated_at
      attr_reader :verification


      def initialize(gateway, attributes) # :nodoc:
        @gateway = gateway
        set_instance_variables_from_hash(attributes)
        @subscriptions = (@subscriptions || []).map { |subscription_hash| Subscription._new(@gateway, subscription_hash) }
        @verification = _most_recent_verification(attributes)
      end

      def _most_recent_verification(attributes)
        verification = (attributes[:verifications] || []).sort_by { |v| v[:created_at] }.reverse.first
        CreditCardVerification._new(verification) if verification
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

      class << self
        protected :new
      end

      def self._attributes # :nodoc:
        [
          :bin, :business, :card_type, :cardholder_name, :commercial,
          :consumer, :container_id, :corporate, :country_of_issuance, :created_at, :customer_id,
          :customer_location, :debit, :durbin_regulated, :expiration_month,
          :expiration_year, :healthcare, :image_url, :issuing_bank, :last_4, :payroll, :prepaid,
          :prepaid_reloadable, :product_id, :purchase, :token, :updated_at
        ]
      end

      def self._new(*args) # :nodoc:
        self.new(*args)
      end
    end
  end
