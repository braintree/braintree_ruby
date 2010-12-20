require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Transaction, "search" do
  context "advanced" do
    it "correctly returns a result with no matches" do
      collection = Braintree::Customer.search do |search|
        search.first_name.is "thisnameisnotreal"
      end

      collection.maximum_size.should == 0
    end

    it "returns one result for text field search" do
      cctoken = "cctoken#{rand(1_000_000)}"
      customer = Braintree::Customer.create!(
        :first_name => "Timmy",
        :last_name => "O'Toole",
        :company => "O'Toole and #{rand(1_000_000)} Son(s)",
        :email => "timmy@example.com",
        :fax => "3145551234",
        :phone => "5551231234",
        :website => "http://example.com",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "05/2010",
          :token => cctoken,
          :billing_address => {
            :first_name => "Thomas",
            :last_name => "Otool",
            :street_address => "1 E Main St",
            :extended_address => "Suite 3",
            :locality => "Chicago",
            :region => "Illinois",
            :postal_code => "60622",
            :country_name => "United States of America"
          }
        }
      )

      customer = Braintree::Customer.find(customer.id)

      search_criteria = {
        :first_name                  => "Timmy",
        :last_name                   => "O'Toole",
        :company                     => customer.company,
        :email                       => "timmy@example.com",
        :phone                       => "5551231234",
        :fax                         => "3145551234",
        :website                     => "http://example.com",
        :address_first_name          => "Thomas",
        :address_last_name           => "Otool",
        :address_street_address      => "1 E Main St",
        :address_postal_code         => "60622",
        :address_extended_address    => "Suite 3",
        :address_locality            => "Chicago",
        :address_region              => "Illinois",
        :payment_method_token        => cctoken,
        :credit_card_expiration_date => "05/2010"
      }

      search_criteria.each do |criterion, value|
        collection = Braintree::Customer.search do |search|
          search.company.is customer.company
          search.send(criterion).is value
        end

        collection.maximum_size.should == 1
        collection.first.id.should == customer.id

        collection = Braintree::Customer.search do |search|
          search.company.is customer.company
          search.send(criterion).is("invalid_attribute")
        end
        collection.should be_empty
      end
    end
  end
end
