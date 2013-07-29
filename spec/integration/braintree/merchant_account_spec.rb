require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

VALID_APPLICATION_PARAMS = {
  :applicant_details => {
    :first_name => "Joe",
    :last_name => "Bloggs",
    :email => "joe@bloggs.com",
    :address => {
      :street_address => "123 Credibility St.",
      :postal_code => "60606",
      :locality => "Chicago",
      :region => "IL",
    },
    :date_of_birth => "10/9/1980",
    :ssn => "123-000-1234",
    :routing_number => "1234567890",
    :account_number => "43759348798"
  },
  :tos_accepted => true,
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
end
