require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::ApplePayCard do
  let(:attributes) do
    {
      :billing_address => {
        company: "Braintree",
        country_code_alpha2: "US",
        country_code_alpha3: "USA",
        country_code_numeric: "840",
        country_name: "United States of America",
        extended_address: "Apt 1",
        first_name: "John",
        last_name: "Miller",
        locality: "Chicago",
        phone_number: "17708675309",
        postal_code: "12345",
        region: "Illinois",
        street_address: "123 Sesame Street",
      },
      :bin => "411111",
      :business => "No",
      :card_type => "Apple Pay - MasterCard",
      :cardholder_name => "John Miller",
      :commercial => "No",
      :consumer => "No",
      :corporate => "No",
      :country_of_issuance => "USA",
      :created_at => Time.now,
      :customer_id => "cid1",
      :debit => "No",
      :default => true,
      :durbin_regulated => "Yes",
      :expiration_month => "01",
      :expiration_year => "2025",
      :expired => false,
      :healthcare => "No",
      :image_url => nil,
      :is_device_token => false,
      :issuing_bank => "Big Bad Bank",
      :last_4 => "9876",
      :merchant_token_identifier => "merchant-token-123",
      :payment_instrument_name => nil,
      :payroll => "No",
      :prepaid => "No",
      :prepaid_reloadable => "No",
      :product_id => "MAC",
      :purchase => "No",
      :source_card_last4 => "1234",
      :source_description => "blah",
      :subscriptions => [
        {
          balance: "50.00",
          price: "10.00",
          descriptor: [],
          transactions: [],
          add_ons: [],
          discounts: [],
        },
      ],
      :token => "123456789",
      :updated_at => Time.now,
    }
  end

  describe "initialize" do
    it "converts billing address hash to Braintree::Address object" do
      card = Braintree::ApplePayCard._new(:gateway, attributes)

      expect(card.billing_address).to be_instance_of(Braintree::Address)
    end

    it "converts subscriptions hash to Braintree::Subscription object" do
      card = Braintree::ApplePayCard._new(:gateway, attributes)

      expect(card.subscriptions[0]).to be_instance_of(Braintree::Subscription)
    end

    it "handles nil billing address" do
      attributes.delete(:billing_address)
      card = Braintree::ApplePayCard._new(:gateway, attributes)

      expect(card.billing_address).to be_nil
    end

    it "handles nil subscriptions" do
      attributes.delete(:subscriptions)
      card = Braintree::ApplePayCard._new(:gateway, attributes)

      expect(card.subscriptions).to be_empty
    end

    it "handles mpan attributes" do
      card = Braintree::ApplePayCard._new(:gateway, attributes)

      expect(card.merchant_token_identifier).to_not be_nil
      expect(card.is_device_token).to_not be_nil
      expect(card.source_card_last4).to_not be_nil
    end
  end

  describe "default?" do
    it "is true if the Apple pay card is the default payment method for the customer" do
      card = Braintree::ApplePayCard._new(:gateway, attributes)

      expect(card.default?).to be true
    end

    it "is false if the Apple pay card is not the default payment methodfor the customer" do
      attributes.merge!(:default => false)
      card = Braintree::ApplePayCard._new(:gateway, attributes)

      expect(card.default?).to be false
    end
  end

  describe "expired?" do
    it "is true if the Apple pay card is expired" do
      attributes.merge!(:expired => true)
      card = Braintree::ApplePayCard._new(:gateway, attributes)

      expect(card.expired?).to be true
    end

    it "is false if the Apple pay card is not expired" do
      card = Braintree::ApplePayCard._new(:gateway, attributes)

      expect(card.expired?).to be false
    end
  end

  describe "self.new" do
    it "is protected" do
      expect do
        Braintree::ApplePayCard.new
      end.to raise_error(NoMethodError, /protected method .new/)
    end
  end
end
