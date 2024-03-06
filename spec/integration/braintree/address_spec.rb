# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Address do
  describe "self.create" do
    it "returns a successful result if valid" do
      customer = Braintree::Customer.create!(:last_name => "Wilson")
      result = Braintree::Address.create(
        :customer_id => customer.id,
        :first_name => "Ben",
        :last_name => "Moore",
        :company => "Moore Co.",
        :street_address => "1811 E Main St",
        :extended_address => "Suite 200",
        :locality => "Chicago",
        :region => "Illinois",
        :phone_number => "5551231234",
        :postal_code => "60622",
        :country_name => "United States of America",
      )
      expect(result.success?).to eq(true)
      expect(result.address.customer_id).to eq(customer.id)
      expect(result.address.first_name).to eq("Ben")
      expect(result.address.last_name).to eq("Moore")
      expect(result.address.company).to eq("Moore Co.")
      expect(result.address.street_address).to eq("1811 E Main St")
      expect(result.address.extended_address).to eq("Suite 200")
      expect(result.address.locality).to eq("Chicago")
      expect(result.address.region).to eq("Illinois")
      expect(result.address.phone_number).to eq("5551231234")
      expect(result.address.postal_code).to eq("60622")
      expect(result.address.country_name).to eq("United States of America")
      expect(result.address.country_code_alpha2).to eq("US")
      expect(result.address.country_code_alpha3).to eq("USA")
      expect(result.address.country_code_numeric).to eq("840")
    end

    it "accepts country_codes" do
      customer = Braintree::Customer.create!
      result = Braintree::Address.create(
        :customer_id => customer.id,
        :country_code_alpha2 => "AS",
        :country_code_alpha3 => "ASM",
        :country_code_numeric => "16",
      )
      expect(result.success?).to eq(true)
      expect(result.address.country_name).to eq("American Samoa")
      expect(result.address.country_code_alpha2).to eq("AS")
      expect(result.address.country_code_alpha3).to eq("ASM")
      expect(result.address.country_code_numeric).to eq("016")
    end

    it "accepts utf-8 country names" do
      customer = Braintree::Customer.create!
      result = Braintree::Address.create(
        :customer_id => customer.id,
        :country_name => "Åland",
      )
      expect(result.success?).to eq(true)
      expect(result.address.country_name).to eq("Åland")
    end

    it "returns an error response given inconsistent country codes" do
      customer = Braintree::Customer.create!
      result = Braintree::Address.create(
        :customer_id => customer.id,
        :country_code_alpha2 => "AS",
        :country_code_alpha3 => "USA",
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:address).on(:base).map { |e| e.code }).to include(Braintree::ErrorCodes::Address::InconsistentCountry)
    end

    it "returns an error response given an invalid country_code_alpha2" do
      customer = Braintree::Customer.create!
      result = Braintree::Address.create(
        :customer_id => customer.id,
        :country_code_alpha2 => "zz",
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:address).on(:country_code_alpha2).map { |e| e.code }).to include(Braintree::ErrorCodes::Address::CountryCodeAlpha2IsNotAccepted)
    end

    it "returns an error response given an invalid country_code_alpha3" do
      customer = Braintree::Customer.create!
      result = Braintree::Address.create(
        :customer_id => customer.id,
        :country_code_alpha3 => "zzz",
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:address).on(:country_code_alpha3).map { |e| e.code }).to include(Braintree::ErrorCodes::Address::CountryCodeAlpha3IsNotAccepted)
    end

    it "returns an error response given an invalid country_code_numeric" do
      customer = Braintree::Customer.create!
      result = Braintree::Address.create(
        :customer_id => customer.id,
        :country_code_numeric => "zz",
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:address).on(:country_code_numeric).map { |e| e.code }).to include(Braintree::ErrorCodes::Address::CountryCodeNumericIsNotAccepted)
    end

    it "returns an error response if invalid" do
      customer = Braintree::Customer.create!(:last_name => "Wilson")
      result = Braintree::Address.create(
        :customer_id => customer.id,
        :country_name => "United States of Invalid",
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:address).on(:country_name)[0].message).to eq("Country name is not an accepted country.")
    end

    it "allows -, _, A-Z, a-z, and 0-9 in customer_id without raising an ArgumentError" do
      expect do
        Braintree::Address.create(:customer_id => "hyphen-")
      end.to raise_error(Braintree::NotFoundError)
      expect do
        Braintree::Address.create(:customer_id => "underscore_")
      end.to raise_error(Braintree::NotFoundError)
      expect do
        Braintree::Address.create(:customer_id => "CAPS")
      end.to raise_error(Braintree::NotFoundError)
    end
  end

  describe "self.create!" do
    it "returns the address if valid" do
      customer = Braintree::Customer.create!(:last_name => "Miller")
      address = Braintree::Address.create!(
        :customer_id => customer.id,
        :street_address => "1812 E Main St",
        :extended_address => "Suite 201",
        :locality => "Bartlett",
        :region => "IL",
        :phone_number => "5551231234",
        :postal_code => "60623",
        :country_name => "United States of America",
      )
      expect(address.customer_id).to eq(customer.id)
      expect(address.street_address).to eq("1812 E Main St")
      expect(address.extended_address).to eq("Suite 201")
      expect(address.locality).to eq("Bartlett")
      expect(address.region).to eq("IL")
      expect(address.phone_number).to eq("5551231234")
      expect(address.postal_code).to eq("60623")
      expect(address.country_name).to eq("United States of America")
    end

    it "raises a ValidationsFailed if invalid" do
      customer = Braintree::Customer.create!(:last_name => "Wilson")
      expect do
        Braintree::Address.create!(
          :customer_id => customer.id,
          :country_name => "United States of Invalid",
        )
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.delete" do
    it "deletes the address given a customer id and an address id" do
      customer = Braintree::Customer.create!(:last_name => "Wilson")
      address = Braintree::Address.create!(:customer_id => customer.id, :street_address => "123 E Main St")
      expect(Braintree::Address.delete(customer.id, address.id).success?).to eq(true)
      expect do
        Braintree::Address.find(customer.id, address.id)
      end.to raise_error(Braintree::NotFoundError)
    end

    it "deletes the address given a customer and an address id" do
      customer = Braintree::Customer.create!(:last_name => "Wilson")
      address = Braintree::Address.create!(:customer_id => customer.id, :street_address => "123 E Main St")
      expect(Braintree::Address.delete(customer, address.id).success?).to eq(true)
      expect do
        Braintree::Address.find(customer.id, address.id)
      end.to raise_error(Braintree::NotFoundError)
    end
  end

  describe "self.find" do
    it "finds the address given a customer and an address id" do
      customer = Braintree::Customer.create!(:last_name => "Wilson")
      address = Braintree::Address.create!(:customer_id => customer.id, :street_address => "123 E Main St")
      expect(Braintree::Address.find(customer, address.id)).to eq(address)
    end

    it "finds the address given a customer id and an address id" do
      customer = Braintree::Customer.create!(:last_name => "Wilson")
      address = Braintree::Address.create!(:customer_id => customer.id, :street_address => "123 E Main St")
      expect(Braintree::Address.find(customer.id, address.id)).to eq(address)
    end

    it "raises a NotFoundError if it cannot be found because of customer id" do
      customer = Braintree::Customer.create!(:last_name => "Wilson")
      address = Braintree::Address.create!(:customer_id => customer.id, :street_address => "123 E Main St")
      expect do
        Braintree::Address.find("invalid", address.id)
      end.to raise_error(
        Braintree::NotFoundError,
        "address for customer \"invalid\" with id #{address.id.inspect} not found")
    end

    it "raises a NotFoundError if it cannot be found because of address id" do
      customer = Braintree::Customer.create!(:last_name => "Wilson")
      Braintree::Address.create!(:customer_id => customer.id, :street_address => "123 E Main St")
      expect do
        Braintree::Address.find(customer, "invalid")
      end.to raise_error(
        Braintree::NotFoundError,
        "address for customer \"#{customer.id}\" with id \"invalid\" not found")
    end
  end

  describe "self.update" do
    it "raises NotFoundError if the address can't be found" do
      customer = Braintree::Customer.create!(:last_name => "Wilson")
      Braintree::Address.create!(:customer_id => customer.id, :street_address => "123 E Main St")
      expect do
        Braintree::Address.update(customer.id, "bad-id", {})
      end.to raise_error(Braintree::NotFoundError)
    end

    it "returns a success response with the updated address if valid" do
      customer = Braintree::Customer.create!(:last_name => "Miller")
      address = Braintree::Address.create!(
        :customer_id => customer.id,
        :street_address => "1812 E Old St",
        :extended_address => "Suite Old 201",
        :locality => "Old Chicago",
        :region => "IL",
        :postal_code => "60620",
        :country_name => "United States of America",
      )
      result = Braintree::Address.update(
        customer.id,
        address.id,
        :street_address => "123 E New St",
        :extended_address => "New Suite 3",
        :locality => "Chicago",
        :region => "Illinois",
        :postal_code => "60621",
        :country_name => "United States of America",
      )
      expect(result.success?).to eq(true)
      expect(result.address.street_address).to eq("123 E New St")
      expect(result.address.extended_address).to eq("New Suite 3")
      expect(result.address.locality).to eq("Chicago")
      expect(result.address.region).to eq("Illinois")
      expect(result.address.postal_code).to eq("60621")
      expect(result.address.country_name).to eq("United States of America")
      expect(result.address.country_code_alpha2).to eq("US")
      expect(result.address.country_code_alpha3).to eq("USA")
      expect(result.address.country_code_numeric).to eq("840")
    end

    it "accepts country_codes" do
      customer = Braintree::Customer.create!(:last_name => "Miller")
      address = Braintree::Address.create!(
        :customer_id => customer.id,
        :country_name => "Angola",
      )
      result = Braintree::Address.update(
        customer.id,
        address.id,
        :country_name => "Azerbaijan",
      )

      expect(result.success?).to eq(true)
      expect(result.address.country_name).to eq("Azerbaijan")
      expect(result.address.country_code_alpha2).to eq("AZ")
      expect(result.address.country_code_alpha3).to eq("AZE")
      expect(result.address.country_code_numeric).to eq("031")
    end

    it "returns an error response if invalid" do
      customer = Braintree::Customer.create!(:last_name => "Miller")
      address = Braintree::Address.create!(
        :customer_id => customer.id,
        :country_name => "United States of America",
      )
      result = Braintree::Address.update(
        customer.id,
        address.id,
        :street_address => "123 E New St",
        :country_name => "United States of Invalid",
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:address).on(:country_name)[0].message).to eq("Country name is not an accepted country.")
    end
  end

  describe "self.update!" do
    it "raises NotFoundError if the address can't be found" do
      customer = Braintree::Customer.create!(:last_name => "Wilson")
      Braintree::Address.create!(:customer_id => customer.id, :street_address => "123 E Main St")
      expect do
        Braintree::Address.update!(customer.id, "bad-id", {})
      end.to raise_error(Braintree::NotFoundError)
    end

    it "returns the updated address if valid" do
      customer = Braintree::Customer.create!(:last_name => "Miller")
      address = Braintree::Address.create!(
        :customer_id => customer.id,
        :street_address => "1812 E Old St",
        :extended_address => "Suite Old 201",
        :locality => "Old Chicago",
        :region => "IL",
        :postal_code => "60620",
        :country_name => "United States of America",
      )
      updated_address = Braintree::Address.update!(
        customer.id,
        address.id,
        :street_address => "123 E New St",
        :extended_address => "New Suite 3",
        :locality => "Chicago",
        :region => "Illinois",
        :postal_code => "60621",
        :country_name => "United States of America",
      )
      expect(updated_address).to eq(address)
      expect(updated_address.street_address).to eq("123 E New St")
      expect(updated_address.extended_address).to eq("New Suite 3")
      expect(updated_address.locality).to eq("Chicago")
      expect(updated_address.region).to eq("Illinois")
      expect(updated_address.postal_code).to eq("60621")
      expect(updated_address.country_name).to eq("United States of America")
    end

    it "raises a ValidationsFailed invalid" do
      customer = Braintree::Customer.create!(:last_name => "Miller")
      address = Braintree::Address.create!(
        :customer_id => customer.id,
        :country_name => "United States of America",
      )
      expect do
        Braintree::Address.update!(
          customer.id,
          address.id,
          :street_address => "123 E New St",
          :country_name => "United States of Invalid",
        )
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end


  describe "delete" do
    it "deletes the address" do
      customer = Braintree::Customer.create!(:last_name => "Wilson")
      address = Braintree::Address.create!(:customer_id => customer.id, :street_address => "123 E Main St")
      result = Braintree::Address.delete(customer.id, address.id)
      expect(result.success?).to eq(true)
      expect do
        Braintree::Address.find(customer.id, address.id)
      end.to raise_error(Braintree::NotFoundError)
    end
  end
end
