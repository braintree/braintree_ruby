require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::MerchantAccount do
  describe "create" do
    it "should allow creation of sub merchant accounts" do
      result = Braintree::MerchantAccount.create(
        :first_name => "Joe",
        :last_name => "Bloggs",
        :email => "joe@bloggs.com",
        :address => {
          :street_address => "123 Credibility St.",
          :extended_address => "Apt. 666",
          :postal_code => "60606",
          :locality => "Chicago",
          :region => "IL",
          :country_code_alpha2 => "US"
        },
        :date_of_birth => "10/9/1980",
        :ssn => "123-000-1234",
        :routing_number => "1234567890",
        :account_number => "43759348798"
      )

      result.success?.should be_true
      result.merchant_account.status.should == Braintree::MerchantAccount::Status::Pending
    end
  end
end
