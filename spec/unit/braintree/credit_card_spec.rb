require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::CreditCard do
  describe "self.create" do
    it "raises an exception if attributes contain an invalid key" do
      expect do
        Braintree::CreditCard.create(:invalid_key => "val")
      end.to raise_error(ArgumentError, "invalid keys: invalid_key")
    end
  end

  describe "self.create_signature" do
    it "should be what we expect" do
      expect(Braintree::CreditCardGateway._create_signature).to match([
        :billing_address_id,
        :cardholder_name,
        :cvv,
        :expiration_date,
        :expiration_month,
        :expiration_year,
        :number,
        :token,
        :venmo_sdk_payment_method_code, # NEXT_MAJOR_VERSION Remove this attribute
        :device_data,
        :payment_method_nonce,
        {:external_vault=>[:network_transaction_id]},
        {:options => match_array([:make_default, :skip_advanced_fraud_checking, :verification_merchant_account_id, :verify_card, :verification_amount, :venmo_sdk_session, # NEXT_MAJOR_VERSION Remove this attribute
          :account_information_inquiry, :fail_on_duplicate_payment_method, :fail_on_duplicate_payment_method_for_customer, :verification_account_type, :verification_currency_iso_code])},
        {:billing_address => [
          :company,
          :country_code_alpha2,
          :country_code_alpha3,
          :country_code_numeric,
          :country_name,
          :extended_address,
          :first_name,
          {:international_phone=>[:country_code, :national_number]},
          :last_name,
          :locality,
          :phone_number,
          :postal_code,
          :region,
          :street_address
        ]},
        {:three_d_secure_pass_thru => [
          :eci_flag,
          :cavv,
          :xid,
          :three_d_secure_version,
          :authentication_response,
          :directory_response,
          :cavv_algorithm,
          :ds_transaction_id,
        ]},
        :customer_id,
      ])
    end
  end

  describe "self.update_signature" do
    it "should be what we expect" do
      expect(Braintree::CreditCardGateway._update_signature).to match([
        :billing_address_id,
        :cardholder_name,
        :cvv,
        :expiration_date,
        :expiration_month,
        :expiration_year,
        :number,
        :token,
        :venmo_sdk_payment_method_code, # NEXT_MAJOR_VERSION Remove this attribute
        :device_data,
        :payment_method_nonce,
        {:external_vault=>[:network_transaction_id]},
        {:options => match_array([:make_default, :skip_advanced_fraud_checking, :verification_merchant_account_id, :verify_card, :verification_amount, :venmo_sdk_session, # NEXT_MAJOR_VERSION Remove this attribute
          :account_information_inquiry, :fail_on_duplicate_payment_method, :fail_on_duplicate_payment_method_for_customer, :verification_account_type, :verification_currency_iso_code])},
        {:billing_address => [
          :company,
          :country_code_alpha2,
          :country_code_alpha3,
          :country_code_numeric,
          :country_name,
          :extended_address,
          :first_name,
          {:international_phone=>[:country_code, :national_number]},
          :last_name,
          :locality,
          :phone_number,
          :postal_code,
          :region,
          :street_address,
          {:options => [:update_existing]}
        ]},
        {:three_d_secure_pass_thru => [
          :eci_flag,
          :cavv,
          :xid,
          :three_d_secure_version,
          :authentication_response,
          :directory_response,
          :cavv_algorithm,
          :ds_transaction_id,
        ]},
      ])
    end
  end

  describe "==" do
    it "returns true if given a credit card with the same token" do
      first = Braintree::CreditCard._new(:gateway, :token => 123)
      second = Braintree::CreditCard._new(:gateway, :token => 123)

      expect(first).to eq(second)
      expect(second).to eq(first)
    end

    it "returns false if given a credit card with a different token" do
      first = Braintree::CreditCard._new(:gateway, :token => 123)
      second = Braintree::CreditCard._new(:gateway, :token => 124)

      expect(first).not_to eq(second)
      expect(second).not_to eq(first)
    end

    it "returns false if not given a credit card" do
      credit_card = Braintree::CreditCard._new(:gateway, :token => 123)
      expect(credit_card).not_to eq("not a credit card")
    end
  end

  describe "default?" do
    it "is true if the credit card is the default credit card for the customer" do
      expect(Braintree::CreditCard._new(:gateway, :default => true).default?).to eq(true)
    end

    it "is false if the credit card is not the default credit card for the customer" do
      expect(Braintree::CreditCard._new(:gateway, :default => false).default?).to eq(false)
    end
  end

  describe "self.find" do
    it "raises error if passed empty string" do
      expect do
        Braintree::CreditCard.find("")
      end.to raise_error(ArgumentError)
    end

    it "raises error if passed invalid string" do
      expect do
        Braintree::CreditCard.find("\t")
      end.to raise_error(ArgumentError)
    end

    it "raises error if passed nil" do
      expect do
        Braintree::CreditCard.find(nil)
      end.to raise_error(ArgumentError)
    end

    it "does not raise an error if address_id does not respond to strip" do
      allow(Braintree::Http).to receive(:new).and_return double.as_null_object
      expect do
        Braintree::CreditCard.find(8675309)
      end.to_not raise_error
    end
  end

  describe "inspect" do
    it "includes the token first" do
      output = Braintree::CreditCard._new(:gateway, :token => "cc123").inspect
      expect(output).to include("#<Braintree::CreditCard token: \"cc123\",")
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
        :updated_at => Time.now,
        :is_network_tokenized => false,
      )
      output = credit_card.inspect
      expect(output).to include(%q(bin: "411111"))
      expect(output).to include(%q(card_type: "Visa"))
      expect(output).to include(%q(cardholder_name: "John Miller"))

      expect(output).to include(%q(customer_id: "cid1"))
      expect(output).to include(%q(expiration_month: "01"))
      expect(output).to include(%q(expiration_year: "2020"))
      expect(output).to include(%q(last_4: "1111"))
      expect(output).to include(%q(token: "tok1"))
      expect(output).to include(%Q(updated_at: #{credit_card.updated_at.inspect}))
      expect(output).to include(%Q(created_at: #{credit_card.created_at.inspect}))
      expect(output).to include(%q(is_network_tokenized?: false))
    end
  end

  describe "masked_number" do
    it "uses the bin and last_4 to build the masked number" do
      credit_card = Braintree::CreditCard._new(
        :gateway,
        :bin => "510510",
        :last_4 => "5100",
      )
      expect(credit_card.masked_number).to eq("510510******5100")
    end
  end

  describe "is_network_tokenized?" do
    it "returns true" do
      credit_card = Braintree::CreditCard._new(
        :gateway,
        :bin => "510510",
        :last_4 => "5100",
        :is_network_tokenized => true,
      )
      expect(credit_card.is_network_tokenized?).to eq(true)
    end

    it "returns false" do
      credit_card = Braintree::CreditCard._new(
        :gateway,
        :bin => "510510",
        :last_4 => "5100",
        :is_network_tokenized => false,
      )
      expect(credit_card.is_network_tokenized?).to eq(false)
    end
  end

  describe "self.update" do
    it "raises an exception if attributes contain an invalid key" do
      expect do
        Braintree::CreditCard.update(:gateway, :invalid_key => "val")
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

  describe "self._new" do
    describe "initializing verification" do
      it "picks the youngest verification" do
        verification1 = {:created_at => Time.now, :id => 123}
        verification2 = {:created_at => Time.now - 3600, :id => 456}
        credit_card = Braintree::CreditCard._new(Braintree::Configuration.gateway, {:verifications => [verification1, verification2]})
        expect(credit_card.verification.id).to eq(123)
      end

      it "picks nil if verifications are empty" do
        credit_card = Braintree::CreditCard._new(Braintree::Configuration.gateway, {})
        expect(credit_card.verification).to be_nil
      end
    end
  end

  it "initializes prepaid reloadable correctly" do
    card = Braintree::CreditCard._new(:gateway, {:prepaid_reloadable => "No"})
    expect(card.prepaid_reloadable).to eq("No")
  end

  it "initializes business correctly" do
    card = Braintree::CreditCard._new(:gateway, {:business => "No"})
    expect(card.business).to eq("No")
  end

  it "initializes consumer correctly" do
    card = Braintree::CreditCard._new(:gateway, {:consumer => "No"})
    expect(card.consumer).to eq("No")
  end

  it "initializes corporate correctly" do
    card = Braintree::CreditCard._new(:gateway, {:corporate => "No"})
    expect(card.corporate).to eq("No")
  end

  it "initializes purchase correctly" do
    card = Braintree::CreditCard._new(:gateway, {:purchase => "No"})
    expect(card.purchase).to eq("No")
  end
end
