require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::MerchantAccount do
  describe "#inspect" do
    it "is a string representation of the merchant account" do
      account = Braintree::MerchantAccount._new(nil, :id => "merchant_account", :status => "active", :master_merchant_account => nil)

      account.inspect.should == "#<Braintree::MerchantAccount: id: \"merchant_account\", status: \"active\", master_merchant_account: nil>"
    end

    it "handles a master merchant account" do
      account = Braintree::MerchantAccount._new(
        nil,
        :id => "merchant_account",
        :status => "active",
        :master_merchant_account => {:id => "master_merchant_account", :status => "active", :master_merchant_account => nil}
      )

      master_merchant_account = "#<Braintree::MerchantAccount: id: \"master_merchant_account\", status: \"active\", master_merchant_account: nil>"
      account.inspect.should == "#<Braintree::MerchantAccount: id: \"merchant_account\", status: \"active\", master_merchant_account: #{master_merchant_account}>"
    end
  end

  describe "_new" do
    it "creates a new Merchant Account with all passed params" do
      params = {
        :id => "sub_merchant_account",
        :status => "active",
        :master_merchant_account => {
          :id => "master_merchant_account",
          :status => "active"
        },
        :individual => {
          :first_name => "John",
          :last_name => "Doe",
          :email => "john.doe@example.com",
          :date_of_birth => "1970-01-01",
          :phone => "3125551234",
          :ssn_last_4 => "6789",
          :address => {
            :street_address => "123 Fake St",
            :locality => "Chicago",
            :region => "IL",
            :postal_code => "60622",
          }
        },
        :business => {
          :dba_name => "James's Bloggs",
          :tax_id => "123456789",
        },
        :funding => {
          :account_number_last_4 => "8798",
          :routing_number => "071000013",
        }
      }

      merchant_account = Braintree::MerchantAccount._new(nil, params)

      merchant_account.status.should == "active"
      merchant_account.id.should == "sub_merchant_account"
      merchant_account.master_merchant_account.id.should == "master_merchant_account"
      merchant_account.master_merchant_account.status.should == "active"
      merchant_account.individual_details.first_name.should == "John"
      merchant_account.individual_details.last_name.should == "Doe"
      merchant_account.individual_details.email.should == "john.doe@example.com"
      merchant_account.individual_details.date_of_birth.should == "1970-01-01"
      merchant_account.individual_details.phone.should == "3125551234"
      merchant_account.individual_details.ssn_last_4.should == "6789"
      merchant_account.individual_details.address_details.street_address.should == "123 Fake St"
      merchant_account.individual_details.address_details.locality.should == "Chicago"
      merchant_account.individual_details.address_details.region.should == "IL"
      merchant_account.individual_details.address_details.postal_code.should == "60622"
      merchant_account.business_details.dba_name.should == "James's Bloggs"
      merchant_account.business_details.tax_id.should == "123456789"
      merchant_account.funding_details.account_number_last_4.should == "8798"
      merchant_account.funding_details.routing_number.should == "071000013"
    end
  end
end
