require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

DEPRECATED_APPLICATION_PARAMS = {
  :applicant_details => {
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
    :routing_number => "011103093",
    :account_number => "43759348798"
  },
  :tos_accepted => true,
  :master_merchant_account_id => "sandbox_master_merchant_account"
}

VALID_APPLICATION_PARAMS = {
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
    :legal_name => "Joe's Bloggs",
    :tax_id => "123456789"
  },
  :funding => {
    :destination => Braintree::MerchantAccount::FundingDestinations::Bank,
    :routing_number => "011103093",
    :account_number => "43759348798"
  },
  :tos_accepted => true,
  :master_merchant_account_id => "sandbox_master_merchant_account"
}

describe Braintree::MerchantAccount do
  describe "create" do
    it "accepts the deprecated parameters" do
      result = Braintree::MerchantAccount.create(DEPRECATED_APPLICATION_PARAMS)

      result.should be_success
      result.merchant_account.status.should == Braintree::MerchantAccount::Status::Pending
      result.merchant_account.master_merchant_account.id.should == "sandbox_master_merchant_account"
    end

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
      result.errors.for(:merchant_account).on(:tos_accepted).first.code.should == Braintree::ErrorCodes::MerchantAccount::TosAcceptedIsRequired
    end

    it "DEPRECATED accepts tax_id and company_name fields" do
      params = DEPRECATED_APPLICATION_PARAMS.clone
      params[:applicant_details][:company_name] = "Test Company"
      params[:applicant_details][:tax_id] = "123456789"
      result = Braintree::MerchantAccount.create(params)
      result.should be_success
      result.merchant_account.status.should == Braintree::MerchantAccount::Status::Pending
    end

    it "accepts tax_id and legal_name fields" do
      params = VALID_APPLICATION_PARAMS.clone
      params[:business][:legal_name] = "Test Company"
      params[:business][:tax_id] = "123456789"
      result = Braintree::MerchantAccount.create(params)
      result.should be_success
      result.merchant_account.status.should == Braintree::MerchantAccount::Status::Pending
    end

    context "funding destination" do
      it "accepts a bank" do
        params = VALID_APPLICATION_PARAMS.dup
        params[:funding][:destination] = ::Braintree::MerchantAccount::FundingDestinations::Bank
        result = Braintree::MerchantAccount.create(params)
      end

      it "accepts an email" do
        params = VALID_APPLICATION_PARAMS.dup
        params[:funding][:destination] = ::Braintree::MerchantAccount::FundingDestinations::Email
        params[:funding][:email] = "joebloggs@compuserve.com"
        result = Braintree::MerchantAccount.create(params)
      end

      it "accepts a mobile_phone" do
        params = VALID_APPLICATION_PARAMS.dup
        params[:funding][:destination] = ::Braintree::MerchantAccount::FundingDestinations::MobilePhone
        params[:funding][:mobile_phone] = "3125882300"
        result = Braintree::MerchantAccount.create(params)
      end
    end
  end

  describe "update" do
    it "updates the Merchant Account info" do
      params = VALID_APPLICATION_PARAMS.clone
      params.delete(:tos_accepted)
      params.delete(:master_merchant_account_id)
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
      params[:business][:legal_name] = "James's Bloggs Inc"
      params[:business][:tax_id] = "123456789"
      params[:funding][:account_number] = "43759348798"
      params[:funding][:routing_number] = "071000013"
      params[:funding][:email] = "check@this.com"
      params[:funding][:mobile_phone] = "1234567890"
      params[:funding][:destination] = Braintree::MerchantAccount::FundingDestinations::MobilePhone
      result = Braintree::MerchantAccount.update("sandbox_sub_merchant_account", params)
      result.should be_success
      result.merchant_account.status.should == "active"
      result.merchant_account.id.should == "sandbox_sub_merchant_account"
      result.merchant_account.master_merchant_account.id.should == "sandbox_master_merchant_account"
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
      result.merchant_account.business_details.legal_name.should == "James's Bloggs Inc"
      result.merchant_account.business_details.tax_id.should == "123456789"
      result.merchant_account.funding_details.account_number_last_4.should == "8798"
      result.merchant_account.funding_details.routing_number.should == "071000013"
      result.merchant_account.funding_details.email.should == "check@this.com"
      result.merchant_account.funding_details.mobile_phone.should == "1234567890"
      result.merchant_account.funding_details.destination.should == Braintree::MerchantAccount::FundingDestinations::MobilePhone
    end

    it "does not require all fields" do
      result = Braintree::MerchantAccount.update("sandbox_sub_merchant_account", { :individual => { :first_name => "Jose" } })
      result.should be_success
    end

    it "handles unsuccessful results" do
      result = Braintree::MerchantAccount.update(
        "sandbox_sub_merchant_account", {
          :individual => {
            :first_name => "",
            :last_name => "",
            :email => "",
            :phone => "",
            :address => {
              :street_address => "",
              :postal_code => "",
              :locality => "",
              :region => "",
            },
            :date_of_birth => "",
            :ssn => "",
          },
          :business => {
            :legal_name => "",
            :dba_name => "",
            :tax_id => ""
          },
          :funding => {
            :destination => "",
            :routing_number => "",
            :account_number => ""
          },
        }
      )

      result.should_not be_success
      result.errors.for(:merchant_account).for(:individual).on(:first_name).map(&:code).should include(Braintree::ErrorCodes::MerchantAccount::Individual::FirstNameIsRequired)
      result.errors.for(:merchant_account).for(:individual).on(:last_name).map(&:code).should include(Braintree::ErrorCodes::MerchantAccount::Individual::LastNameIsRequired)
      result.errors.for(:merchant_account).for(:individual).on(:date_of_birth).map(&:code).should include(Braintree::ErrorCodes::MerchantAccount::Individual::DateOfBirthIsRequired)
      result.errors.for(:merchant_account).for(:individual).on(:email).map(&:code).should include(Braintree::ErrorCodes::MerchantAccount::Individual::EmailIsRequired)
      result.errors.for(:merchant_account).for(:individual).for(:address).on(:street_address).map(&:code).should  include(Braintree::ErrorCodes::MerchantAccount::Individual::Address::StreetAddressIsRequired)
      result.errors.for(:merchant_account).for(:individual).for(:address).on(:postal_code).map(&:code).should include(Braintree::ErrorCodes::MerchantAccount::Individual::Address::PostalCodeIsRequired)
      result.errors.for(:merchant_account).for(:individual).for(:address).on(:locality).map(&:code).should include(Braintree::ErrorCodes::MerchantAccount::Individual::Address::LocalityIsRequired)
      result.errors.for(:merchant_account).for(:individual).for(:address).on(:region).map(&:code).should include(Braintree::ErrorCodes::MerchantAccount::Individual::Address::RegionIsRequired)
      result.errors.for(:merchant_account).for(:funding).on(:destination).map(&:code).should include(Braintree::ErrorCodes::MerchantAccount::Funding::DestinationIsRequired)
      result.errors.for(:merchant_account).on(:base).should be_empty
    end
  end
end
