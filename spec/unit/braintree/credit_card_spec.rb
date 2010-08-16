require File.dirname(__FILE__) + "/../spec_helper"

describe Braintree::CreditCard do
  describe "self.create" do
    it "raises an exception if attributes contain an invalid key" do
      expect do
        Braintree::CreditCard.create(:invalid_key => 'val')
      end.to raise_error(ArgumentError, "invalid keys: invalid_key")
    end
  end

  describe "self.create_signature" do
    it "should be what we expect" do
      Braintree::CreditCardGateway._create_signature.should == [
        :cardholder_name,
        :cvv,
        :expiration_date,
        :expiration_month,
        :expiration_year,
        :number,
        :token,
        {:options => [:make_default, :verification_merchant_account_id, :verify_card]},
        {:billing_address => [
          :company,
          :country_code_alpha2,
          :country_code_alpha3,
          :country_code_numeric,
          :country_name,
          :extended_address,
          :first_name,
          :last_name,
          :locality,
          :postal_code,
          :region,
          :street_address
        ]},
        :customer_id
      ]
    end
  end

  describe "self.update_signature" do
    it "should be what we expect" do
      Braintree::CreditCardGateway._update_signature.should == [
        :cardholder_name,
        :cvv,
        :expiration_date,
        :expiration_month,
        :expiration_year,
        :number,
        :token,
        {:options => [:make_default, :verification_merchant_account_id, :verify_card]},
        {:billing_address => [
          :company,
          :country_code_alpha2,
          :country_code_alpha3,
          :country_code_numeric,
          :country_name,
          :extended_address,
          :first_name,
          :last_name,
          :locality,
          :postal_code,
          :region,
          :street_address,
          {:options => [:update_existing]}
        ]}
      ]
    end
  end

  describe "self.create_from_transparent_redirect" do
    it "raises an exception if the query string is forged" do
      expect do
        Braintree::CreditCard.create_from_transparent_redirect("http_status=200&forged=query_string")
      end.to raise_error(Braintree::ForgedQueryString)
    end
  end

  describe "self.create_credit_card_url" do
    it "returns the url" do
      port = Braintree::Configuration.instantiate.port
      Braintree::CreditCard.create_credit_card_url.should == "http://localhost:#{port}/merchants/integration_merchant_id/payment_methods/all/create_via_transparent_redirect_request"
    end
  end

  describe "==" do
    it "returns true if given a credit card with the same token" do
      first = Braintree::CreditCard._new(:gateway, :token => 123)
      second = Braintree::CreditCard._new(:gateway, :token => 123)

      first.should == second
      second.should == first
    end

    it "returns false if given a credit card with a different token" do
      first = Braintree::CreditCard._new(:gateway, :token => 123)
      second = Braintree::CreditCard._new(:gateway, :token => 124)

      first.should_not == second
      second.should_not == first
    end

    it "returns false if not given a credit card" do
      credit_card = Braintree::CreditCard._new(:gateway, :token => 123)
      credit_card.should_not == "not a credit card"
    end
  end

  describe "default?" do
    it "is true if the credit card is the default credit card for the customer" do
      Braintree::CreditCard._new(:gateway, :default => true).default?.should == true
    end

    it "is false if the credit card is not the default credit card for the customer" do
      Braintree::CreditCard._new(:gateway, :default => false).default?.should == false
    end
  end

  describe "inspect" do
    it "includes the token first" do
      output = Braintree::CreditCard._new(:gateway, :token => "cc123").inspect
      output.should include("#<Braintree::CreditCard token: \"cc123\",")
    end

    it "includes all customer attributes" do
      credit_card = Braintree::CreditCard._new(
        :gateway,
        :bin => "411111",
        :card_type => "Visa",
        :cardholder_name => "John Miller",
        :created_at => Time.now,
        :customer_id => "cid1",
        :expiration_month => "01",
        :expiration_year => "2020",
        :last_4 => "1111",
        :token => "tok1",
        :updated_at => Time.now
      )
      output = credit_card.inspect
      output.should include(%q(bin: "411111"))
      output.should include(%q(card_type: "Visa"))
      output.should include(%q(cardholder_name: "John Miller"))

      output.should include(%q(customer_id: "cid1"))
      output.should include(%q(expiration_month: "01"))
      output.should include(%q(expiration_year: "2020"))
      output.should include(%q(last_4: "1111"))
      output.should include(%q(token: "tok1"))
      output.should include(%Q(updated_at: #{credit_card.updated_at.inspect}))
      output.should include(%Q(created_at: #{credit_card.created_at.inspect}))
    end
  end

  describe "masked_number" do
    it "uses the bin and last_4 to build the masked number" do
      credit_card = Braintree::CreditCard._new(
        :gateway,
        :bin => "510510",
        :last_4 => "5100"
      )
      credit_card.masked_number.should == "510510******5100"
    end
  end

  describe "self.update" do
    it "raises an exception if attributes contain an invalid key" do
      expect do
        Braintree::CreditCard._new(Braintree::Configuration.gateway, {}).update(:invalid_key => 'val')
      end.to raise_error(ArgumentError, "invalid keys: invalid_key")
    end
  end

  describe "self.new" do
    it "is protected" do
      expect do
        Braintree::CreditCard.new
      end.to raise_error(NoMethodError, /protected method .new/)
    end
  end
end
