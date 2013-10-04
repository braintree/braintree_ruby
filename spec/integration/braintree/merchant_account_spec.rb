require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

VALID_APPLICATION_PARAMS = {
  :applicant_details => {
    :first_name => "Joe",
    :last_name => "Bloggs",
    :email => "joe@bloggs.com",
    :phone => "312-555-1234",
    :address => {
      :street_address => "123 Credibility St.",
      :postal_code => "60606",
      :locality => "Chicago",
      :region => "IL",
    },
    :date_of_birth => "10/9/1980",
    :ssn => "123-00-1234",
    :routing_number => "1234567890",
    :account_number => "43759348798"
  },
  :tos_accepted => true,
  :master_merchant_account_id => "sandbox_master_merchant_account"
}

VALID_MERCHANT_ACCOUNT_PARAMS = {
  :individual => {
    :first_name => "Joe",
    :last_name => "Bloggs",
    :email => "joe@bloggs.com",
    :phone => "3125551234",
    :address => {
      :street_address => "123 Credibility St.",
      :postal_code => "60606",
      :locality => "Chicago",
      :region => "IL",
    },
    :date_of_birth => "10/9/1980",
    :ssn => "123-00-1234",
  },
  :business => {
    :dba_name => "Joe's Bloggs",
    :tax_id => "123456789"
  },
  :funding => {
    :routing_number => "1234567890",
    :account_number => "43759348798"
  },
  :id => "sandbox_sub_merchant_account",
  :master_merchant_account_id => "sandbox_master_merchant_account"
}

describe Braintree::MerchantAccount do
  describe "create" do
    it "doesn't require an id" do
      result = Braintree::MerchantAccount.create(VALID_APPLICATION_PARAMS)

      result.should be_success
      result.merchant_account.status.should == Braintree::MerchantAccount::Status::Pending
      result.merchant_account.master_merchant_account.id.should == "sandbox_master_merchant_account"
    end

    it "allows an id to be passed" do
      random_number = rand(10000)
      sub_merchant_account_id = "sub_merchant_account_id#{random_number}"
      result = Braintree::MerchantAccount.create(
        VALID_APPLICATION_PARAMS.merge(
          :id => sub_merchant_account_id
        )
      )

      result.should be_success
      result.merchant_account.status.should == Braintree::MerchantAccount::Status::Pending
      result.merchant_account.id.should == sub_merchant_account_id
      result.merchant_account.master_merchant_account.id.should == "sandbox_master_merchant_account"
    end

    it "handles unsuccessful results" do
      result = Braintree::MerchantAccount.create({})
      result.should_not be_success
      result.errors.for(:merchant_account).on(:master_merchant_account_id).first.code.should == Braintree::ErrorCodes::MerchantAccount::MasterMerchantAccountIdIsRequired
    end

    it "requires all fields" do
      result = Braintree::MerchantAccount.create(
        :master_merchant_account_id => "sandbox_master_merchant_account"
      )
      result.should_not be_success
      result.errors.for(:merchant_account).for(:applicant_details).on(:first_name).first.code.should == Braintree::ErrorCodes::MerchantAccount::ApplicantDetails::FirstNameIsRequired
    end

    it "accepts tax_id and business_name fields" do
      params = VALID_APPLICATION_PARAMS.clone
      params[:applicant_details][:company_name] = "Test Company"
      params[:applicant_details][:tax_id] = "123456789"
      result = Braintree::MerchantAccount.create(params)
      result.should be_success
      result.merchant_account.status.should == Braintree::MerchantAccount::Status::Pending
    end
  end

  describe "update" do
    it "updates the Merchant Account info" do
      params = VALID_MERCHANT_ACCOUNT_PARAMS.clone
      params[:individual][:first_name] = "John"
      params[:individual][:last_name] = "Doe"
      params[:individual][:email] = "john.doe@example.com"
      params[:individual][:date_of_birth] = "1970-01-01"
      params[:individual][:phone] = "3125551234"
      params[:individual][:address][:street_address] = "123 Fake St"
      params[:individual][:address][:locality] = "Chicago"
      params[:individual][:address][:region] = "IL"
      params[:individual][:address][:postal_code] = "60622"
      params[:business][:dba_name] = "James's Bloggs"
      params[:business][:tax_id] = "123456789"
      params[:funding][:account_number] = "43759348798"
      params[:funding][:routing_number] = "071000013"

      result = Braintree::MerchantAccount.update("sandbox_sub_merchant_account", params)

      result.should be_success
      result.merchant_account.individual_details.first_name.should == "John"
      result.merchant_account.individual_details.last_name.should == "Doe"
      result.merchant_account.individual_details.email.should == "john.doe@example.com"
      result.merchant_account.individual_details.date_of_birth.should == "1970-01-01"
      result.merchant_account.individual_details.phone.should == "3125551234"
      result.merchant_account.individual_details.address_details.street_address.should == "123 Fake St"
      result.merchant_account.individual_details.address_details.locality.should == "Chicago"
      result.merchant_account.individual_details.address_details.region.should == "IL"
      result.merchant_account.individual_details.address_details.postal_code.should == "60622"
      result.merchant_account.business_details.dba_name.should == "James's Bloggs"
    end

    it "does not require all fields" do
      result = Braintree::MerchantAccount.update("sandbox_sub_merchant_account", { :individual => { :first_name => "Jose" } })

      result.should be_success
    end

    it "handles unsuccessful results" do
      result = Braintree::MerchantAccount.update("sandbox_sub_merchant_account", { :individual => { :first_name => "" } })
      result.should_not be_success
      result.errors.for(:merchant_account).for(:individual).on(:first_name).first.code.should == Braintree::ErrorCodes::MerchantAccount::Individual::FirstNameIsRequired
    end
  end
end
