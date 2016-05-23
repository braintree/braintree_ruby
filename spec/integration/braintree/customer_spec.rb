# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::Customer do
  describe "self.all" do
    it "gets more than a page of customers" do
      customers = Braintree::Customer.all
      customers.maximum_size.should > 100

      customer_ids = customers.map {|c| c.id }.uniq.compact
      customer_ids.size.should == customers.maximum_size
    end
  end

  describe "self.delete" do
    it "deletes the customer with the given id" do
     create_result = Braintree::Customer.create(
        :first_name => "Joe",
        :last_name => "Cool"
      )
      create_result.success?.should == true
      customer = create_result.customer

      delete_result = Braintree::Customer.delete(customer.id)
      delete_result.success?.should == true
      expect do
        Braintree::Customer.find(customer.id)
      end.to raise_error(Braintree::NotFoundError)
    end
  end

  describe "self.create" do
    it "returns a successful result if successful" do
      result = Braintree::Customer.create(
        :first_name => "Bill",
        :last_name => "Gates",
        :company => "Microsoft",
        :email => "bill@microsoft.com",
        :phone => "312.555.1234",
        :fax => "614.555.5678",
        :website => "www.microsoft.com"
      )
      result.success?.should == true
      result.customer.id.should =~ /^\d{6,}$/
      result.customer.first_name.should == "Bill"
      result.customer.last_name.should == "Gates"
      result.customer.company.should == "Microsoft"
      result.customer.email.should == "bill@microsoft.com"
      result.customer.phone.should == "312.555.1234"
      result.customer.fax.should == "614.555.5678"
      result.customer.website.should == "www.microsoft.com"
      result.customer.created_at.between?(Time.now - 10, Time.now).should == true
      result.customer.updated_at.between?(Time.now - 10, Time.now).should == true
    end

    it "returns a successful result if successful using an access token" do
      oauth_gateway = Braintree::Gateway.new(
        :client_id => "client_id$#{Braintree::Configuration.environment}$integration_client_id",
        :client_secret => "client_secret$#{Braintree::Configuration.environment}$integration_client_secret",
        :logger => Logger.new("/dev/null")
      )
      access_token = Braintree::OAuthTestHelper.create_token(oauth_gateway, {
        :merchant_public_id => "integration_merchant_id",
        :scope => "read_write"
      }).credentials.access_token

      gateway = Braintree::Gateway.new(
        :access_token => access_token,
        :logger => Logger.new("/dev/null")
      )

      result = gateway.customer.create(
        :first_name => "Joe",
        :last_name => "Brown",
        :company => "ExampleCo",
        :email => "joe@example.com",
        :phone => "312.555.1234",
        :fax => "614.555.5678",
        :website => "www.example.com"
      )
      result.success?.should == true
      result.customer.id.should =~ /^\d{6,}$/
      result.customer.first_name.should == "Joe"
      result.customer.last_name.should == "Brown"
    end

    it "supports creation with a device session ID and (optional) fraud_merchant_id" do
      result = Braintree::Customer.create(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "05/2010",
          :cvv => "100",
          :device_session_id => "abc123",
          :fraud_merchant_id => "7"
        }
      )

      result.should be_success
    end

    it "can create without any attributes" do
      result = Braintree::Customer.create
      result.success?.should == true
    end

    it "supports utf-8" do
      first_name = "Jos\303\251"
      last_name = "Mu\303\261oz"
      result = Braintree::Customer.create(:first_name => first_name, :last_name => last_name)
      result.success?.should == true

      if RUBY_VERSION =~ /^1.8/
        result.customer.first_name.should == first_name
        result.customer.last_name.should == last_name

        found_customer = Braintree::Customer.find(result.customer.id)
        found_customer.first_name.should == first_name
        found_customer.last_name.should == last_name
      else
        result.customer.first_name.should == "José"
        result.customer.first_name.bytes.map {|b| b.to_s(8)}.should == ["112", "157", "163", "303", "251"]
        result.customer.last_name.should == "Muñoz"
        result.customer.last_name.bytes.map {|b| b.to_s(8)}.should == ["115", "165", "303", "261", "157", "172"]

        found_customer = Braintree::Customer.find(result.customer.id)
        found_customer.first_name.should == "José"
        found_customer.first_name.bytes.map {|b| b.to_s(8)}.should == ["112", "157", "163", "303", "251"]
        found_customer.last_name.should == "Muñoz"
        found_customer.last_name.bytes.map {|b| b.to_s(8)}.should == ["115", "165", "303", "261", "157", "172"]
      end
    end

    it "returns an error response if invalid" do
      result = Braintree::Customer.create(
        :email => "@invalid.com"
      )
      result.success?.should == false
      result.errors.for(:customer).on(:email)[0].message.should == "Email is an invalid format."
    end

    it "can create a customer and a payment method at the same time" do
      result = Braintree::Customer.create(
        :first_name => "Mike",
        :last_name => "Jones",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "05/2010",
          :cvv => "100"
        }
      )
      result.success?.should == true
      result.customer.first_name.should == "Mike"
      result.customer.last_name.should == "Jones"
      result.customer.credit_cards[0].bin.should == Braintree::Test::CreditCardNumbers::MasterCard[0, 6]
      result.customer.credit_cards[0].last_4.should == Braintree::Test::CreditCardNumbers::MasterCard[-4..-1]
      result.customer.credit_cards[0].expiration_date.should == "05/2010"
      result.customer.credit_cards[0].unique_number_identifier.should =~ /\A\w{32}\z/
    end

    it "verifies the card if credit_card[options][verify_card]=true" do
      result = Braintree::Customer.create(
        :first_name => "Mike",
        :last_name => "Jones",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::MasterCard,
          :expiration_date => "05/2010",
          :options => {:verify_card => true}
        }
      )
      result.success?.should == false
      result.credit_card_verification.status.should == Braintree::Transaction::Status::ProcessorDeclined
    end

    it "allows a verification_amount" do
      result = Braintree::Customer.create(
        :first_name => "Mike",
        :last_name => "Jones",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "05/2019",
          :options => {:verify_card => true, :verification_amount => "2.00"}
        }
      )
      result.success?.should == true
    end

    it "fails on create if credit_card[options][fail_on_duplicate_payment_method]=true and there is a duplicated payment method" do
      customer = Braintree::Customer.create!
      Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2015"
      )

      result = Braintree::Customer.create(
        :first_name => "Mike",
        :last_name => "Jones",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2015",
          :options => {:fail_on_duplicate_payment_method => true}
        }
      )
      result.success?.should == false
      result.errors.for(:customer).for(:credit_card).on(:number)[0].message.should == "Duplicate card exists in the vault."
    end

    it "allows the user to specify the merchant account for verification" do
      result = Braintree::Customer.create(
        :first_name => "Mike",
        :last_name => "Jones",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::MasterCard,
          :expiration_date => "05/2010",
          :options => {
            :verify_card => true,
            :verification_merchant_account_id => SpecHelper::NonDefaultMerchantAccountId
          }
        }
      )
      result.success?.should == false
      result.credit_card_verification.status.should == Braintree::Transaction::Status::ProcessorDeclined
    end

    it "can create a customer, payment method, and billing address at the same time" do
      result = Braintree::Customer.create(
        :first_name => "Mike",
        :last_name => "Jones",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "05/2010",
          :billing_address => {
            :street_address => "1 E Main St",
            :extended_address => "Suite 3",
            :locality => "Chicago",
            :region => "Illinois",
            :postal_code => "60622",
            :country_name => "United States of America"
          }
        }
      )
      result.success?.should == true
      result.customer.first_name.should == "Mike"
      result.customer.last_name.should == "Jones"
      result.customer.credit_cards[0].bin.should == Braintree::Test::CreditCardNumbers::MasterCard[0, 6]
      result.customer.credit_cards[0].last_4.should == Braintree::Test::CreditCardNumbers::MasterCard[-4..-1]
      result.customer.credit_cards[0].expiration_date.should == "05/2010"
      result.customer.credit_cards[0].billing_address.id.should == result.customer.addresses[0].id
      result.customer.addresses[0].id.should =~ /\w+/
      result.customer.addresses[0].street_address.should == "1 E Main St"
      result.customer.addresses[0].extended_address.should == "Suite 3"
      result.customer.addresses[0].locality.should == "Chicago"
      result.customer.addresses[0].region.should == "Illinois"
      result.customer.addresses[0].postal_code.should == "60622"
      result.customer.addresses[0].country_name.should == "United States of America"
    end

    it "can use any country code" do
      result = Braintree::Customer.create(
        :first_name => "James",
        :last_name => "Conroy",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "05/2010",
          :billing_address => {
            :country_name => "Comoros",
            :country_code_alpha2 => "KM",
            :country_code_alpha3 => "COM",
            :country_code_numeric => "174"
          }
        }
      )
      result.success?.should == true
      result.customer.addresses[0].country_name.should == "Comoros"
      result.customer.addresses[0].country_code_alpha2.should == "KM"
      result.customer.addresses[0].country_code_alpha3.should == "COM"
      result.customer.addresses[0].country_code_numeric.should == "174"
    end

    it "stores custom fields when valid" do
      result = Braintree::Customer.create(
        :first_name => "Bill",
        :last_name => "Gates",
        :custom_fields => {
          :store_me => "custom value"
        }
      )
      result.success?.should == true
      result.customer.custom_fields[:store_me].should == "custom value"
    end

    it "returns empty hash for custom fields when blank" do
      result = Braintree::Customer.create(
        :first_name => "Bill",
        :last_name => "Gates",
        :custom_fields => { :store_me => "" }
      )
      result.success?.should == true
      result.customer.custom_fields.should == {}
    end

    it "returns nested errors if credit card and/or billing address are invalid" do
      result = Braintree::Customer.create(
        :email => "invalid",
        :credit_card => {
          :number => "invalidnumber",
          :billing_address => {
            :country_name => "invalid"
          }
        }
      )
      result.success?.should == false
      result.errors.for(:customer).on(:email)[0].message.should == "Email is an invalid format."
      result.errors.for(:customer).for(:credit_card).on(:number)[0].message.should == "Credit card number is invalid."
      result.errors.for(:customer).for(:credit_card).for(:billing_address).on(:country_name)[0].message.should == "Country name is not an accepted country."
    end

    it "returns errors if country codes are inconsistent" do
      result = Braintree::Customer.create(
        :first_name => "Olivia",
        :last_name => "Dupree",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "05/2010",
          :billing_address => {
            :country_name => "Comoros",
            :country_code_alpha2 => "US",
            :country_code_alpha3 => "COM",
          }
        }
      )
      result.success?.should == false
      result.errors.for(:customer).for(:credit_card).for(:billing_address).on(:base).map {|e| e.code}.should include(Braintree::ErrorCodes::Address::InconsistentCountry)
    end

    it "returns an error if country code alpha2 is invalid" do
      result = Braintree::Customer.create(
        :first_name => "Melissa",
        :last_name => "Henderson",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "05/2010",
          :billing_address => {
            :country_code_alpha2 => "zz",
          }
        }
      )
      result.success?.should == false
      result.errors.for(:customer).for(:credit_card).for(:billing_address).on(:country_code_alpha2).map {|e| e.code}.should include(Braintree::ErrorCodes::Address::CountryCodeAlpha2IsNotAccepted)
    end

    it "returns an error if country code alpha3 is invalid" do
      result = Braintree::Customer.create(
        :first_name => "Andrew",
        :last_name => "Patterson",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "05/3010",
          :billing_address => {
            :country_code_alpha3 => "zzz",
          }
        }
      )
      result.success?.should == false
      result.errors.for(:customer).for(:credit_card).for(:billing_address).on(:country_code_alpha3).map {|e| e.code}.should include(Braintree::ErrorCodes::Address::CountryCodeAlpha3IsNotAccepted)
    end

    it "returns an error if country code numeric is invalid" do
      result = Braintree::Customer.create(
        :first_name => "Steve",
        :last_name => "Hamlin",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "05/3010",
          :billing_address => {
            :country_code_numeric => "zzz",
          }
        }
      )
      result.success?.should == false
      result.errors.for(:customer).for(:credit_card).for(:billing_address).on(:country_code_numeric).map {|e| e.code}.should include(Braintree::ErrorCodes::Address::CountryCodeNumericIsNotAccepted)
    end

    it "returns errors if custom_fields are not registered" do
      result = Braintree::Customer.create(
        :first_name => "Jack",
        :last_name => "Kennedy",
        :custom_fields => {
          :spouse_name => "Jacqueline"
        }
      )
      result.success?.should == false
      result.errors.for(:customer).on(:custom_fields)[0].message.should == "Custom field is invalid: spouse_name."
    end

    describe "venmo_sdk" do
      it "can create a customer with a venmo sdk payment method code" do
        result = Braintree::Customer.create(
          :first_name => "Steve",
          :last_name => "Hamlin",
          :credit_card => {
            :venmo_sdk_payment_method_code => Braintree::Test::VenmoSDK::VisaPaymentMethodCode
          }
        )
        result.success?.should == true
        result.customer.credit_cards.first.bin.should == "400934"
        result.customer.credit_cards.first.last_4.should == "1881"
      end

      it "can create a customer with a venmo sdk session" do
        result = Braintree::Customer.create(
          :first_name => "Steve",
          :last_name => "Hamlin",
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::MasterCard,
            :expiration_date => "05/2010",
            :options => {
              :venmo_sdk_session => Braintree::Test::VenmoSDK::Session
            }
          }
        )
        result.success?.should == true
        result.customer.credit_cards.first.venmo_sdk?.should == true
      end
    end

    context "client API" do
      it "can create a customer with a payment method nonce" do
        nonce = nonce_for_new_payment_method(
          :credit_card => {
            :number => "4111111111111111",
            :expiration_month => "11",
            :expiration_year => "2099",
          },
          :share => true
        )

        result = Braintree::Customer.create(
          :credit_card => {
            :payment_method_nonce => nonce
          }
        )

        result.success?.should == true
        result.customer.credit_cards.first.bin.should == "411111"
        result.customer.credit_cards.first.last_4.should == "1111"
      end
    end

    it "can create a customer with an apple pay payment method" do
      result = Braintree::Customer.create(:payment_method_nonce => Braintree::Test::Nonce::ApplePayVisa)

      result.success?.should == true
      result.customer.payment_methods.should_not be_empty
      result.customer.payment_methods.first.token.should_not be_nil
    end

    it "can create a customer with an unknown payment method" do
      result = Braintree::Customer.create(:payment_method_nonce => Braintree::Test::Nonce::AbstractTransactable)

      result.success?.should == true
    end
  end

  describe "self.create!" do
    it "returns the customer if successful" do
      customer = Braintree::Customer.create!(
        :first_name => "Jim",
        :last_name => "Smith"
      )
      customer.id.should =~ /\d+/
      customer.first_name.should == "Jim"
      customer.last_name.should == "Smith"
    end

    it "can create without any attributes" do
      customer = Braintree::Customer.create!
      customer.id.should =~ /\d+/
    end

    it "raises an exception if not successful" do
      expect do
        Braintree::Customer.create!(:email => "@foo.com")
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.credit" do
    it "creates a credit transaction for given customer id, returning a result object" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      result = Braintree::Customer.credit(customer.id, :amount => "100.00")
      result.success?.should == true
      result.transaction.amount.should == BigDecimal.new("100.00")
      result.transaction.type.should == "credit"
      result.transaction.customer_details.id.should == customer.id
      result.transaction.credit_card_details.token.should == customer.credit_cards[0].token
      result.transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      result.transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      result.transaction.credit_card_details.expiration_date.should == "05/2010"
    end
  end

  describe "self.credit!" do
    it "creates a credit transaction for given customer id, returning a result object" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      transaction = Braintree::Customer.credit!(customer.id, :amount => "100.00")
      transaction.amount.should == BigDecimal.new("100.00")
      transaction.type.should == "credit"
      transaction.customer_details.id.should == customer.id
      transaction.credit_card_details.token.should == customer.credit_cards[0].token
      transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      transaction.credit_card_details.expiration_date.should == "05/2010"
    end
  end

  describe "self.sale" do
    it "creates a sale transaction for given customer id, returning a result object" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      result = Braintree::Customer.sale(customer.id, :amount => "100.00")
      result.success?.should == true
      result.transaction.amount.should == BigDecimal.new("100.00")
      result.transaction.type.should == "sale"
      result.transaction.customer_details.id.should == customer.id
      result.transaction.credit_card_details.token.should == customer.credit_cards[0].token
      result.transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      result.transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      result.transaction.credit_card_details.expiration_date.should == "05/2010"
    end
  end

  describe "self.sale!" do
    it "creates a sale transaction for given customer id, returning the transaction" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      transaction = Braintree::Customer.sale!(customer.id, :amount => "100.00")
      transaction.amount.should == BigDecimal.new("100.00")
      transaction.type.should == "sale"
      transaction.customer_details.id.should == customer.id
      transaction.credit_card_details.token.should == customer.credit_cards[0].token
      transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      transaction.credit_card_details.expiration_date.should == "05/2010"
    end
  end

  describe "self.transactions" do
    it "finds transactions for the given customer id" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      transaction = customer.sale!(:amount => "100.00")
      collection = Braintree::Customer.transactions(customer.id)
      collection.first.should == transaction
    end
  end


  describe "sale" do
    it "creates a sale transaction using the customer, returning a result object" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      result = customer.sale(
        :amount => "100.00"
      )
      result.success?.should == true
      result.transaction.amount.should == BigDecimal.new("100.00")
      result.transaction.type.should == "sale"
      result.transaction.customer_details.id.should == customer.id
      result.transaction.credit_card_details.token.should == customer.credit_cards[0].token
      result.transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      result.transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      result.transaction.credit_card_details.expiration_date.should == "05/2010"
    end
  end

  describe "sale!" do
    it "returns the created sale tranaction if valid" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      transaction = customer.sale!(:amount => "100.00")
      transaction.amount.should == BigDecimal.new("100.00")
      transaction.type.should == "sale"
      transaction.customer_details.id.should == customer.id
      transaction.credit_card_details.token.should == customer.credit_cards[0].token
      transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      transaction.credit_card_details.expiration_date.should == "05/2010"
    end
  end

  describe "transactions" do
    it "finds transactions for the customer" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      transaction = customer.sale!(:amount => "100.00")
      collection = customer.transactions
      collection.first.should == transaction
    end
  end

  describe "credit" do
    it "creates a credit transaction using the customer, returning a result object" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      result = customer.credit(
        :amount => "100.00"
      )
      result.success?.should == true
      result.transaction.amount.should == BigDecimal.new("100.00")
      result.transaction.type.should == "credit"
      result.transaction.customer_details.id.should == customer.id
      result.transaction.credit_card_details.token.should == customer.credit_cards[0].token
      result.transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      result.transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      result.transaction.credit_card_details.expiration_date.should == "05/2010"
    end
  end

  describe "credit!" do
    it "returns the created credit tranaction if valid" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      transaction = customer.credit!(:amount => "100.00")
      transaction.amount.should == BigDecimal.new("100.00")
      transaction.type.should == "credit"
      transaction.customer_details.id.should == customer.id
      transaction.credit_card_details.token.should == customer.credit_cards[0].token
      transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      transaction.credit_card_details.expiration_date.should == "05/2010"
    end
  end

  describe "create_from_transparent_redirect" do
    it "returns a successful result if successful" do
      params = {
        :customer => {
          :first_name => "John",
          :last_name => "Doe",
          :company => "Doe Co",
          :email => "john@doe.com",
          :phone => "312.555.2323",
          :fax => "614.555.5656",
          :website => "www.johndoe.com"
        }
      }

      tr_data = Braintree::TransparentRedirect.create_customer_data({:redirect_url => "http://example.com"}.merge({}))
      query_string_response = SpecHelper.simulate_form_post_for_tr(tr_data, params, Braintree::Customer.create_customer_url)
      result = Braintree::Customer.create_from_transparent_redirect(query_string_response)

      result.success?.should == true
      customer = result.customer
      customer.first_name.should == "John"
      customer.last_name.should == "Doe"
      customer.company.should == "Doe Co"
      customer.email.should == "john@doe.com"
      customer.phone.should == "312.555.2323"
      customer.fax.should == "614.555.5656"
      customer.website.should == "www.johndoe.com"
    end

    it "can pass any attribute through tr_data" do
      customer_id = "customer_#{rand(1_000_000)}"
      tr_data_params = {
        :customer => {
          :id => customer_id,
          :first_name => "John",
          :last_name => "Doe",
          :company => "Doe Co",
          :email => "john@doe.com",
          :phone => "312.555.2323",
          :fax => "614.555.5656",
          :website => "www.johndoe.com"
        }
      }

      tr_data = Braintree::TransparentRedirect.create_customer_data({:redirect_url => "http://example.com"}.merge(tr_data_params))
      query_string_response = SpecHelper.simulate_form_post_for_tr(tr_data, {}, Braintree::Customer.create_customer_url)
      result = Braintree::Customer.create_from_transparent_redirect(query_string_response)

      result.success?.should == true
      customer = result.customer
      customer.id.should == customer_id
      customer.first_name.should == "John"
      customer.last_name.should == "Doe"
      customer.company.should == "Doe Co"
      customer.email.should == "john@doe.com"
      customer.phone.should == "312.555.2323"
      customer.fax.should == "614.555.5656"
      customer.website.should == "www.johndoe.com"
    end
  end

  describe "delete" do
    it "deletes the customer" do
     result = Braintree::Customer.create(
        :first_name => "Joe",
        :last_name => "Cool"
      )
      result.success?.should == true

      customer = result.customer
      customer.delete.success?.should == true
      expect do
        Braintree::Customer.find(customer.id)
      end.to raise_error(Braintree::NotFoundError)
    end
  end


  describe "self.find" do
    it "finds the customer with the given id" do
      result = Braintree::Customer.create(
        :first_name => "Joe",
        :last_name => "Cool"
      )
      result.success?.should == true

      customer = Braintree::Customer.find(result.customer.id)
      customer.id.should == result.customer.id
      customer.first_name.should == "Joe"
      customer.last_name.should == "Cool"
    end

    it "returns associated subscriptions" do
      customer = Braintree::Customer.create.customer
      credit_card = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2012"
      ).credit_card

      subscription = Braintree::Subscription.create(
        :payment_method_token => credit_card.token,
        :plan_id => "integration_trialless_plan",
        :price => "1.00"
      ).subscription

      found_customer = Braintree::Customer.find(customer.id)
      found_customer.credit_cards.first.subscriptions.first.id.should == subscription.id
      found_customer.credit_cards.first.subscriptions.first.plan_id.should == "integration_trialless_plan"
      found_customer.credit_cards.first.subscriptions.first.payment_method_token.should == credit_card.token
      found_customer.credit_cards.first.subscriptions.first.price.should == BigDecimal.new("1.00")
    end

    it "returns associated ApplePayCards" do
      result = Braintree::Customer.create(
        :payment_method_nonce => Braintree::Test::Nonce::ApplePayAmEx
      )
      result.success?.should == true

      found_customer = Braintree::Customer.find(result.customer.id)
      found_customer.apple_pay_cards.should_not be_nil
      apple_pay_card = found_customer.apple_pay_cards.first
      apple_pay_card.should be_a Braintree::ApplePayCard
      apple_pay_card.token.should_not be_nil
      apple_pay_card.expiration_year.should_not be_nil
      apple_pay_card.payment_instrument_name.should == "AmEx 41002"
    end

    it "returns associated android pay proxy cards" do
      result = Braintree::Customer.create(
        :payment_method_nonce => Braintree::Test::Nonce::AndroidPayDiscover
      )
      result.success?.should == true

      found_customer = Braintree::Customer.find(result.customer.id)
      found_customer.android_pay_cards.size.should == 1
      found_customer.payment_methods.size.should == 1
      android_pay_card = found_customer.android_pay_cards.first
      android_pay_card.should be_a Braintree::AndroidPayCard
      android_pay_card.token.should_not be_nil
      android_pay_card.expiration_year.should_not be_nil
    end

    it "returns associated android pay network tokens" do
      result = Braintree::Customer.create(
        :payment_method_nonce => Braintree::Test::Nonce::AndroidPayMasterCard
      )
      result.success?.should == true

      found_customer = Braintree::Customer.find(result.customer.id)
      found_customer.android_pay_cards.size.should == 1
      found_customer.payment_methods.size.should == 1
      android_pay_card = found_customer.android_pay_cards.first
      android_pay_card.should be_a Braintree::AndroidPayCard
      android_pay_card.token.should_not be_nil
      android_pay_card.expiration_year.should_not be_nil
    end

    it "returns associated amex express checkout cards" do
      result = Braintree::Customer.create(
        :payment_method_nonce => Braintree::Test::Nonce::AmexExpressCheckout
      )
      result.success?.should == true

      found_customer = Braintree::Customer.find(result.customer.id)
      found_customer.amex_express_checkout_cards.size.should == 1
      found_customer.payment_methods.size.should == 1
      amex_express_checkout_card = found_customer.amex_express_checkout_cards.first
      amex_express_checkout_card.should be_a Braintree::AmexExpressCheckoutCard
      amex_express_checkout_card.token.should_not be_nil
      amex_express_checkout_card.expiration_year.should_not be_nil
    end

    it "returns associated venmo accounts" do
      result = Braintree::Customer.create(
        :payment_method_nonce => Braintree::Test::Nonce::VenmoAccount
      )
      result.success?.should == true

      found_customer = Braintree::Customer.find(result.customer.id)
      found_customer.venmo_accounts.size.should == 1
      found_customer.payment_methods.size.should == 1
      venmo_account = found_customer.venmo_accounts.first
      venmo_account.should be_a Braintree::VenmoAccount
      venmo_account.token.should_not be_nil
      venmo_account.username.should_not be_nil
    end

    it "works for a blank customer" do
      created_customer = Braintree::Customer.create!
      found_customer = Braintree::Customer.find(created_customer.id)
      found_customer.id.should == created_customer.id
    end

    it "raises an ArgumentError if customer_id is not a string" do
      expect do
        Braintree::Customer.find(Object.new)
      end.to raise_error(ArgumentError, "customer_id contains invalid characters")
    end

    it "raises an ArgumentError if customer_id is blank" do
      expect do
        Braintree::Customer.find("")
      end.to raise_error(ArgumentError, "customer_id contains invalid characters")
    end

    it "raises a NotFoundError exception if customer cannot be found" do
      expect do
        Braintree::Customer.find("invalid-id")
      end.to raise_error(Braintree::NotFoundError, 'customer with id "invalid-id" not found')
    end
  end

  describe "self.update" do
    it "updates the customer with the given id if successful" do
      customer = Braintree::Customer.create!(
        :first_name => "Joe",
        :last_name => "Cool"
      )
      result = Braintree::Customer.update(
        customer.id,
        :first_name => "Mr. Joe",
        :last_name => "Super Cool",
        :custom_fields => {
          :store_me => "a value"
        }
      )
      result.success?.should == true
      result.customer.id.should == customer.id
      result.customer.first_name.should == "Mr. Joe"
      result.customer.last_name.should == "Super Cool"
      result.customer.custom_fields[:store_me].should == "a value"
    end

    it "can use any country code" do
      customer = Braintree::Customer.create!(
        :first_name => "Alex",
        :last_name => "Matterson"
      )
      result = Braintree::Customer.update(
        customer.id,
        :first_name => "Sammy",
        :last_name => "Banderton",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "05/2010",
          :billing_address => {
            :country_name => "Fiji",
            :country_code_alpha2 => "FJ",
            :country_code_alpha3 => "FJI",
            :country_code_numeric => "242"
          }
        }
      )
      result.success?.should == true
      result.customer.addresses[0].country_name.should == "Fiji"
      result.customer.addresses[0].country_code_alpha2.should == "FJ"
      result.customer.addresses[0].country_code_alpha3.should == "FJI"
      result.customer.addresses[0].country_code_numeric.should == "242"
    end

    it "can update the customer, credit card, and billing address in one request" do
      customer = Braintree::Customer.create!(
        :first_name => "Joe",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "12/2009",
          :billing_address => {
            :first_name => "Joe",
            :postal_code => "60622"
          }
        }
      )

      result = Braintree::Customer.update(
        customer.id,
        :first_name => "New Joe",
        :credit_card => {
          :cardholder_name => "New Joe Cardholder",
          :options => { :update_existing_token => customer.credit_cards.first.token },
          :billing_address => {
            :last_name => "Cool",
            :postal_code => "60666",
            :options => { :update_existing => true }
          }
        }
      )
      result.success?.should == true
      result.customer.id.should == customer.id
      result.customer.first_name.should == "New Joe"

      result.customer.credit_cards.size.should == 1
      credit_card = result.customer.credit_cards.first
      credit_card.bin.should == Braintree::Test::CreditCardNumbers::Visa.slice(0, 6)
      credit_card.cardholder_name.should == "New Joe Cardholder"

      credit_card.billing_address.first_name.should == "Joe"
      credit_card.billing_address.last_name.should == "Cool"
      credit_card.billing_address.postal_code.should == "60666"
    end

    it "can update the customer and verify_card with a specific verification_amount" do
      customer = Braintree::Customer.create!(
        :first_name => "Joe"
      )

      result = Braintree::Customer.update(
        customer.id,
        :first_name => "New Joe",
        :credit_card => {
          :cardholder_name => "New Joe Cardholder",
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "12/2009",
          :options => { :verify_card => true, :verification_amount => "2.00" }
        }
      )
      result.success?.should == true
    end

    it "can update the nested billing address with billing_address_id" do
      customer = Braintree::Customer.create!

      address = Braintree::Address.create!(
        :customer_id => customer.id,
        :first_name => "John",
        :last_name => "Doe"
      )

      customer = Braintree::Customer.update(
        customer.id,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "12/2009",
          :billing_address_id => address.id
        }
      ).customer

      billing_address = customer.credit_cards.first.billing_address
      billing_address.id.should == address.id
      billing_address.first_name.should == "John"
      billing_address.last_name.should == "Doe"
    end

    it "returns an error response if invalid" do
      customer = Braintree::Customer.create!(:email => "valid@email.com")
      result = Braintree::Customer.update(
        customer.id,
        :email => "@invalid.com"
      )
      result.success?.should == false
      result.errors.for(:customer).on(:email)[0].message.should == "Email is an invalid format."
    end
  end

  describe "self.update!" do
    it "returns the updated customer if successful" do
      customer = Braintree::Customer.create!(
        :first_name => "Joe",
        :last_name => "Cool"
      )
      updated_customer = Braintree::Customer.update!(
        customer.id,
        :first_name => "Mr. Joe",
        :last_name => "Super Cool"
      )
      updated_customer.first_name.should == "Mr. Joe"
      updated_customer.last_name.should == "Super Cool"
      updated_customer.updated_at.between?(Time.now - 60, Time.now).should == true
    end

    it "raises an error if unsuccessful" do
      customer = Braintree::Customer.create!(:email => "valid@email.com")
      expect do
        Braintree::Customer.update!(customer.id, :email => "@invalid.com")
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "update" do
    it "updates the customer" do
      customer = Braintree::Customer.create!(
        :first_name => "Joe",
        :last_name => "Cool"
      )
      update_result = customer.update(
        :first_name => "Mr. Joe",
        :last_name => "Super Cool"
      )
      update_result.success?.should == true
      update_result.customer.should == customer
      updated_customer = update_result.customer
      updated_customer.first_name.should == "Mr. Joe"
      updated_customer.last_name.should == "Super Cool"
    end

    it "returns an error response if invalid" do
      customer = Braintree::Customer.create!(
        :email => "valid@email.com"
      )
      result = customer.update(
        :email => "@invalid.com"
      )
      result.success?.should == false
      result.errors.for(:customer).on(:email)[0].message.should == "Email is an invalid format."
    end
  end

  describe "update!" do
    it "returns the customer and updates the customer if successful" do
      customer = Braintree::Customer.create!(
        :first_name => "Joe",
        :last_name => "Cool"
      )
      customer.update!(
        :first_name => "Mr. Joe",
        :last_name => "Super Cool"
      ).should == customer
      customer.first_name.should == "Mr. Joe"
      customer.last_name.should == "Super Cool"
      customer.updated_at.between?(Time.now - 60, Time.now).should == true
    end

    it "raises an error if unsuccessful" do
      customer = Braintree::Customer.create!(
        :email => "valid@email.com"
      )
      expect do
        customer.update!(:email => "@invalid.com")
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "update_from_transparent_redirect" do
    it "returns a successful result if successful" do
      result = Braintree::Customer.create(
        :first_name => "Old First",
        :last_name => "Old Last",
        :company => "Old Company",
        :email => "old@email.com",
        :phone => "000.111.2222",
        :fax => "000.222.3333",
        :website => "old.website.com"
      )
      result.success?.should == true
      original_customer = result.customer
      params = {
        :customer => {
          :first_name => "New First",
          :last_name => "New Last",
          :company => "New Company",
          :email => "new@email.com",
          :phone => "888.111.2222",
          :fax => "999.222.3333",
          :website => "new.website.com"
        }
      }
      tr_data_params = {
        :customer_id => original_customer.id
      }

      tr_data = Braintree::TransparentRedirect.update_customer_data({:redirect_url => "http://example.com"}.merge(tr_data_params))
      query_string_response = SpecHelper.simulate_form_post_for_tr(tr_data, params, Braintree::Customer.update_customer_url)
      result = Braintree::Customer.update_from_transparent_redirect(query_string_response)

      result.success?.should == true
      customer = result.customer
      customer.id.should == original_customer.id
      customer.first_name.should == "New First"
      customer.last_name.should == "New Last"
      customer.company.should == "New Company"
      customer.email.should == "new@email.com"
      customer.phone.should == "888.111.2222"
      customer.fax.should == "999.222.3333"
      customer.website.should == "new.website.com"
    end

    it "returns a successful result when updating an existing credit card" do
      result = Braintree::Customer.create(
        :first_name => "Old First",
        :last_name => "Old Last",
        :company => "Old Company",
        :email => "old@email.com",
        :phone => "000.111.2222",
        :fax => "000.222.3333",
        :website => "old.website.com",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "12/2009",
          :billing_address => {
            :first_name => "Joe",
            :postal_code => "60622"
          }
        }
      )
      result.success?.should == true
      original_customer = result.customer

      tr_data_params = {
        :customer_id => original_customer.id,
        :customer => {
          :first_name => "New First",
          :last_name => "New Last",
          :company => "New Company",
          :email => "new@email.com",
          :phone => "888.111.2222",
          :fax => "999.222.3333",
          :website => "new.website.com",
          :credit_card => {
            :cardholder_name => "New Joe Cardholder",
            :options => { :update_existing_token => original_customer.credit_cards.first.token },
            :billing_address => {
              :last_name => "Cool",
              :postal_code => "60666",
              :options => { :update_existing => true }
            }
          }
        }
      }

      tr_data = Braintree::TransparentRedirect.update_customer_data({:redirect_url => "http://example.com"}.merge(tr_data_params))
      query_string_response = SpecHelper.simulate_form_post_for_tr(tr_data, {}, Braintree::Customer.update_customer_url)
      result = Braintree::Customer.update_from_transparent_redirect(query_string_response)

      result.success?.should == true
      customer = result.customer
      customer.id.should == original_customer.id
      customer.first_name.should == "New First"
      customer.last_name.should == "New Last"
      customer.company.should == "New Company"
      customer.email.should == "new@email.com"
      customer.phone.should == "888.111.2222"
      customer.fax.should == "999.222.3333"
      customer.website.should == "new.website.com"

      credit_card = customer.credit_cards.first
      credit_card.bin.should == Braintree::Test::CreditCardNumbers::Visa.slice(0, 6)
      credit_card.cardholder_name.should == "New Joe Cardholder"

      credit_card.billing_address.first_name.should == "Joe"
      credit_card.billing_address.last_name.should == "Cool"
      credit_card.billing_address.postal_code.should == "60666"
    end

    it "can pass any attribute through tr_data" do
      original_customer = Braintree::Customer.create!(
        :first_name => "Old First",
        :last_name => "Old Last",
        :company => "Old Company",
        :email => "old@email.com",
        :phone => "000.111.2222",
        :fax => "000.222.3333",
        :website => "old.website.com"
      )
      new_customer_id = "customer_#{rand(1_000_000)}"
      tr_data_params = {
        :customer_id => original_customer.id,
        :customer => {
          :id => new_customer_id,
          :first_name => "New First",
          :last_name => "New Last",
          :company => "New Company",
          :email => "new@email.com",
          :phone => "888.111.2222",
          :fax => "999.222.3333",
          :website => "new.website.com"
        }
      }

      tr_data = Braintree::TransparentRedirect.update_customer_data({:redirect_url => "http://example.com"}.merge(tr_data_params))
      query_string_response = SpecHelper.simulate_form_post_for_tr(tr_data, {}, Braintree::Customer.update_customer_url)
      result = Braintree::Customer.update_from_transparent_redirect(query_string_response)

      result.success?.should == true
      customer = result.customer
      customer.id.should == new_customer_id
      customer.first_name.should == "New First"
      customer.last_name.should == "New Last"
      customer.company.should == "New Company"
      customer.email.should == "new@email.com"
      customer.phone.should == "888.111.2222"
      customer.fax.should == "999.222.3333"
      customer.website.should == "new.website.com"
    end
  end

  describe "default_credit_card" do
    it "should return the default credit card for a given customer" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "12/2015",
          :options => {
            :make_default => false
          }
        }
      )

      default_credit_card = Braintree::CreditCard.create!(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::MasterCard,
        :expiration_date => "11/2015",
        :options => {
          :make_default => true
        }
      )

      customer = Braintree::Customer.find(customer.id)

      customer.default_credit_card.should == default_credit_card
    end
  end

  describe "paypal" do
    context "future" do
      it "creates a customer with a future paypal account" do
        result = Braintree::Customer.create(
          :payment_method_nonce => Braintree::Test::Nonce::PayPalFuturePayment
        )

        result.should be_success
      end

      it "updates a customer with a future paypal account" do
        customer = Braintree::Customer.create!(
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/2015",
            :options => {
              :make_default => true
            }
          }
        )

        paypal_account_token = "PAYPAL_ACCOUNT_TOKEN_#{rand(36**3).to_s(36)}"
        nonce = nonce_for_paypal_account(
          :consent_code => "PAYPAL_CONSENT_CODE",
          :token => paypal_account_token,
          :options => {
            :make_default => true
          }
        )

        result = Braintree::Customer.update(
          customer.id,
          :payment_method_nonce => nonce
        )

        result.should be_success
        result.customer.default_payment_method.token.should == paypal_account_token
      end
    end

    context "onetime" do
      it "does not create a customer with a onetime paypal account" do
        result = Braintree::Customer.create(
          :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment
        )

        result.should_not be_success
      end

      it "does not update a customer with a onetime paypal account" do
        credit_card_token = rand(36**3).to_s(36)
        customer = Braintree::Customer.create!(
          :credit_card => {
            :token => credit_card_token,
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/2015",
            :options => {
              :make_default => true
            }
          }
        )

        paypal_account_token = "PAYPAL_ACCOUNT_TOKEN_#{rand(36**3).to_s(36)}"
        nonce = nonce_for_paypal_account(
          :access_token => "PAYPAL_ACCESS_TOKEN",
          :token => paypal_account_token,
          :options => {
            :make_default => true
          }
        )

        result = Braintree::Customer.update(
          customer.id,
          :payment_method_nonce => nonce
        )

        result.should_not be_success
        customer.default_payment_method.token.should == credit_card_token
      end
    end
  end
end
