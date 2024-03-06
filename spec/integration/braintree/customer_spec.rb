# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::Customer do
  describe "self.all" do
    it "gets more than a page of customers" do
      customers = Braintree::Customer.all
      expect(customers.maximum_size).to be > 100

      customer_ids = customers.map { |c| c.id }.uniq.compact
      expect(customer_ids.size).to eq(customers.maximum_size)
    end
  end

  describe "self.delete" do
    it "deletes the customer with the given id" do
     create_result = Braintree::Customer.create(
        :first_name => "Joe",
        :last_name => "Cool",
      )
      expect(create_result.success?).to eq(true)
      customer = create_result.customer

      delete_result = Braintree::Customer.delete(customer.id)
      expect(delete_result.success?).to eq(true)
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
        :website => "www.microsoft.com",
        :tax_identifiers => [{:country_code => "US", :identifier => "987654321"}],
      )
      expect(result.success?).to eq(true)
      expect(result.customer.id).to match(/^\d{6,}$/)
      expect(result.customer.first_name).to eq("Bill")
      expect(result.customer.last_name).to eq("Gates")
      expect(result.customer.company).to eq("Microsoft")
      expect(result.customer.email).to eq("bill@microsoft.com")
      expect(result.customer.phone).to eq("312.555.1234")
      expect(result.customer.fax).to eq("614.555.5678")
      expect(result.customer.website).to eq("www.microsoft.com")
      expect(result.customer.created_at.between?(Time.now - 10, Time.now)).to eq(true)
      expect(result.customer.updated_at.between?(Time.now - 10, Time.now)).to eq(true)
    end

    it "returns a successful result if successful using an access token" do
      oauth_gateway = Braintree::Gateway.new(
        :client_id => "client_id$#{Braintree::Configuration.environment}$integration_client_id",
        :client_secret => "client_secret$#{Braintree::Configuration.environment}$integration_client_secret",
        :logger => Logger.new("/dev/null"),
      )
      access_token = Braintree::OAuthTestHelper.create_token(oauth_gateway, {
        :merchant_public_id => "integration_merchant_id",
        :scope => "read_write"
      }).credentials.access_token

      gateway = Braintree::Gateway.new(
        :access_token => access_token,
        :logger => Logger.new("/dev/null"),
      )

      result = gateway.customer.create(
        :first_name => "Joe",
        :last_name => "Brown",
        :company => "ExampleCo",
        :email => "joe@example.com",
        :phone => "312.555.1234",
        :fax => "614.555.5678",
        :website => "www.example.com",
      )
      expect(result.success?).to eq(true)
      expect(result.customer.id).to match(/^\d{6,}$/)
      expect(result.customer.first_name).to eq("Joe")
      expect(result.customer.last_name).to eq("Brown")
    end

    it "supports creation with device_data" do
      result = Braintree::Customer.create(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "05/2010",
          :cvv => "100",
          :device_data => "device_data",
        },
      )

      expect(result).to be_success
    end

    it "supports creation including risk data with customer_browser and customer_ip" do
      result = Braintree::Customer.create(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "05/2010",
          :cvv => "100"
        },
        :risk_data => {
          :customer_browser => "IE5",
          :customer_ip => "192.168.0.1"
        },
      )

      expect(result).to be_success
    end

    it "includes risk data when skip_advanced_fraud_checking is false" do
      with_fraud_protection_enterprise_merchant do
        result = Braintree::Customer.create(
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::MasterCard,
            :expiration_date => "05/2010",
            :cvv => "100",
            :options => {
              :skip_advanced_fraud_checking => false,
              :verify_card => true,
            },
          },
        )

        expect(result).to be_success
        verification = result.customer.credit_cards.first.verification
        expect(verification.risk_data).not_to be_nil
      end
    end

    it "does not include risk data when skip_advanced_fraud_checking is true" do
      with_fraud_protection_enterprise_merchant do
        result = Braintree::Customer.create(
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::MasterCard,
            :expiration_date => "05/2010",
            :cvv => "100",
            :options => {
              :skip_advanced_fraud_checking => true,
              :verify_card => true,
            },
          },
        )

        expect(result).to be_success
        verification = result.customer.credit_cards.first.verification
        expect(verification.risk_data).to be_nil
      end
    end

    it "supports creation with tax_identifiers" do
      result = Braintree::Customer.create(
        :tax_identifiers => [
          {:country_code => "US", :identifier => "987654321"},
          {:country_code => "CL", :identifier => "123456789"}
        ],
      )

      expect(result).to be_success
    end

    it "can create without any attributes" do
      result = Braintree::Customer.create
      expect(result.success?).to eq(true)
    end

    it "supports utf-8" do
      first_name = "Jos\303\251"
      last_name = "Mu\303\261oz"
      result = Braintree::Customer.create(:first_name => first_name, :last_name => last_name)
      expect(result.success?).to eq(true)

      if RUBY_VERSION =~ /^1.8/
        expect(result.customer.first_name).to eq(first_name)
        expect(result.customer.last_name).to eq(last_name)

        found_customer = Braintree::Customer.find(result.customer.id)
        expect(found_customer.first_name).to eq(first_name)
        expect(found_customer.last_name).to eq(last_name)
      else
        expect(result.customer.first_name).to eq("José")
        expect(result.customer.first_name.bytes.map { |b| b.to_s(8) }).to eq(["112", "157", "163", "303", "251"])
        expect(result.customer.last_name).to eq("Muñoz")
        expect(result.customer.last_name.bytes.map { |b| b.to_s(8) }).to eq(["115", "165", "303", "261", "157", "172"])

        found_customer = Braintree::Customer.find(result.customer.id)
        expect(found_customer.first_name).to eq("José")
        expect(found_customer.first_name.bytes.map { |b| b.to_s(8) }).to eq(["112", "157", "163", "303", "251"])
        expect(found_customer.last_name).to eq("Muñoz")
        expect(found_customer.last_name.bytes.map { |b| b.to_s(8) }).to eq(["115", "165", "303", "261", "157", "172"])
      end
    end

    it "returns an error response if invalid" do
      result = Braintree::Customer.create(
        :email => "@invalid.com",
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:customer).on(:email)[0].message).to eq("Email is an invalid format.")
    end

    it "can create a customer and a payment method at the same time" do
      result = Braintree::Customer.create(
        :first_name => "Mike",
        :last_name => "Jones",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "05/2010",
          :cvv => "100"
        },
      )

      expect(result.success?).to eq(true)
      expect(result.customer.first_name).to eq("Mike")
      expect(result.customer.last_name).to eq("Jones")
      expect(result.customer.credit_cards[0].bin).to eq(Braintree::Test::CreditCardNumbers::MasterCard[0, 6])
      expect(result.customer.credit_cards[0].last_4).to eq(Braintree::Test::CreditCardNumbers::MasterCard[-4..-1])
      expect(result.customer.credit_cards[0].expiration_date).to eq("05/2010")
      expect(result.customer.credit_cards[0].unique_number_identifier).to match(/\A\w{32}\z/)
    end

    it "can create a customer and a paypal account at the same time" do
      result = Braintree::Customer.create(
        :first_name => "Mike",
        :last_name => "Jones",
        :paypal_account => {
          :email => "other@example.com",
          :billing_agreement_id => "B-123456",
          :options => {:make_default => true}
        },
      )

      expect(result.success?).to eq(true)
      expect(result.customer.first_name).to eq("Mike")
      expect(result.customer.last_name).to eq("Jones")
      expect(result.customer.paypal_accounts[0].billing_agreement_id).to eq("B-123456")
      expect(result.customer.paypal_accounts[0].email).to eq("other@example.com")
    end

    it "verifies the card if credit_card[options][verify_card]=true" do
      result = Braintree::Customer.create(
        :first_name => "Mike",
        :last_name => "Jones",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::MasterCard,
          :expiration_date => "05/2010",
          :options => {:verify_card => true}
        },
      )
      expect(result.success?).to eq(false)
      expect(result.credit_card_verification.status).to eq(Braintree::Transaction::Status::ProcessorDeclined)
    end

    it "allows a verification_amount" do
      result = Braintree::Customer.create(
        :first_name => "Mike",
        :last_name => "Jones",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "05/2019",
          :options => {:verify_card => true, :verification_amount => "2.00"}
        },
      )
      expect(result.success?).to eq(true)
    end

    it "fails on create if credit_card[options][fail_on_duplicate_payment_method]=true and there is a duplicated payment method" do
      customer = Braintree::Customer.create!
      Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2015",
      )

      result = Braintree::Customer.create(
        :first_name => "Mike",
        :last_name => "Jones",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2015",
          :options => {:fail_on_duplicate_payment_method => true}
        },
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:customer).for(:credit_card).on(:number)[0].message).to eq("Duplicate card exists in the vault.")
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
        },
      )
      expect(result.success?).to eq(false)
      expect(result.credit_card_verification.status).to eq(Braintree::Transaction::Status::ProcessorDeclined)
    end

    it "can create a customer and a payment method at the same time after validating verification_currency_iso_code" do
      result = Braintree::Customer.create(
        :first_name => "Mike",
        :last_name => "Jones",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "05/2010",
          :cvv => "100",
          :options => {
            :verify_card => true,
            :verification_currency_iso_code => "USD"
          }
        },
      )

      expect(result.success?).to eq(true)
      expect(result.customer.first_name).to eq("Mike")
      expect(result.customer.last_name).to eq("Jones")
      expect(result.customer.credit_cards[0].bin).to eq(Braintree::Test::CreditCardNumbers::MasterCard[0, 6])
      expect(result.customer.credit_cards[0].last_4).to eq(Braintree::Test::CreditCardNumbers::MasterCard[-4..-1])
      expect(result.customer.credit_cards[0].expiration_date).to eq("05/2010")
      expect(result.customer.credit_cards[0].unique_number_identifier).to match(/\A\w{32}\z/)
      result.customer.credit_cards[0].verification.currency_iso_code == "USD"
    end

    it "errors when verification_currency_iso_code is not supported by merchant account" do
      result = Braintree::Customer.create(
        :first_name => "Mike",
        :last_name => "Jones",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "05/2010",
          :cvv => "100",
          :options => {
            :verify_card => true,
            :verification_currency_iso_code => "GBP"
          }
        },
      )
      expect(result).to_not be_success
      expect(result.errors.for(:customer).for(:credit_card).for(:options).on(:verification_currency_iso_code)[0].code).to eq Braintree::ErrorCodes::CreditCard::CurrencyCodeNotSupportedByMerchantAccount
    end

    it "validates verification_currency_iso_code of the given verification_merchant_account_id and creates customer" do
      result = Braintree::Customer.create(
        :first_name => "Mike",
        :last_name => "Jones",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "05/2010",
          :options => {
            :verify_card => true,
            :verification_merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,
            :verification_currency_iso_code => "USD"
          }
        },
      )
      expect(result.success?).to eq(true)
      result.customer.credit_cards[0].verification.currency_iso_code == "USD"
      expect(result.customer.first_name).to eq("Mike")
      expect(result.customer.last_name).to eq("Jones")
      expect(result.customer.credit_cards[0].bin).to eq(Braintree::Test::CreditCardNumbers::MasterCard[0, 6])
      expect(result.customer.credit_cards[0].last_4).to eq(Braintree::Test::CreditCardNumbers::MasterCard[-4..-1])
      expect(result.customer.credit_cards[0].expiration_date).to eq("05/2010")
      expect(result.customer.credit_cards[0].unique_number_identifier).to match(/\A\w{32}\z/)
    end

    it "validates verification_currency_iso_code of the given verification_merchant_account_id and returns error" do
      result = Braintree::Customer.create(
        :first_name => "Mike",
        :last_name => "Jones",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "05/2010",
          :options => {
            :verify_card => true,
            :verification_merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,
            :verification_currency_iso_code => "GBP"
          }
        },
      )
      expect(result).to_not be_success
      expect(result.errors.for(:customer).for(:credit_card).for(:options).on(:verification_currency_iso_code)[0].code).to eq Braintree::ErrorCodes::CreditCard::CurrencyCodeNotSupportedByMerchantAccount
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
        },
      )
      expect(result.success?).to eq(true)
      expect(result.customer.first_name).to eq("Mike")
      expect(result.customer.last_name).to eq("Jones")
      expect(result.customer.credit_cards[0].bin).to eq(Braintree::Test::CreditCardNumbers::MasterCard[0, 6])
      expect(result.customer.credit_cards[0].last_4).to eq(Braintree::Test::CreditCardNumbers::MasterCard[-4..-1])
      expect(result.customer.credit_cards[0].expiration_date).to eq("05/2010")
      expect(result.customer.credit_cards[0].billing_address.id).to eq(result.customer.addresses[0].id)
      expect(result.customer.addresses[0].id).to match(/\w+/)
      expect(result.customer.addresses[0].street_address).to eq("1 E Main St")
      expect(result.customer.addresses[0].extended_address).to eq("Suite 3")
      expect(result.customer.addresses[0].locality).to eq("Chicago")
      expect(result.customer.addresses[0].region).to eq("Illinois")
      expect(result.customer.addresses[0].postal_code).to eq("60622")
      expect(result.customer.addresses[0].country_name).to eq("United States of America")
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
        },
      )
      expect(result.success?).to eq(true)
      expect(result.customer.addresses[0].country_name).to eq("Comoros")
      expect(result.customer.addresses[0].country_code_alpha2).to eq("KM")
      expect(result.customer.addresses[0].country_code_alpha3).to eq("COM")
      expect(result.customer.addresses[0].country_code_numeric).to eq("174")
    end

    it "stores custom fields when valid" do
      result = Braintree::Customer.create(
        :first_name => "Bill",
        :last_name => "Gates",
        :custom_fields => {
          :store_me => "custom value"
        },
      )
      expect(result.success?).to eq(true)
      expect(result.customer.custom_fields[:store_me]).to eq("custom value")
    end

    it "returns empty hash for custom fields when blank" do
      result = Braintree::Customer.create(
        :first_name => "Bill",
        :last_name => "Gates",
        :custom_fields => {:store_me => ""},
      )
      expect(result.success?).to eq(true)
      expect(result.customer.custom_fields).to eq({})
    end

    it "returns nested errors if credit card and/or billing address are invalid" do
      result = Braintree::Customer.create(
        :email => "invalid",
        :credit_card => {
          :number => "invalidnumber",
          :billing_address => {
            :country_name => "invalid"
          }
        },
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:customer).on(:email)[0].message).to eq("Email is an invalid format.")
      expect(result.errors.for(:customer).for(:credit_card).on(:number)[0].message).to eq("Credit card number is invalid.")
      expect(result.errors.for(:customer).for(:credit_card).for(:billing_address).on(:country_name)[0].message).to eq("Country name is not an accepted country.")
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
        },
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:customer).for(:credit_card).for(:billing_address).on(:base).map { |e| e.code }).to include(Braintree::ErrorCodes::Address::InconsistentCountry)
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
        },
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:customer).for(:credit_card).for(:billing_address).on(:country_code_alpha2).map { |e| e.code }).to include(Braintree::ErrorCodes::Address::CountryCodeAlpha2IsNotAccepted)
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
        },
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:customer).for(:credit_card).for(:billing_address).on(:country_code_alpha3).map { |e| e.code }).to include(Braintree::ErrorCodes::Address::CountryCodeAlpha3IsNotAccepted)
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
        },
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:customer).for(:credit_card).for(:billing_address).on(:country_code_numeric).map { |e| e.code }).to include(Braintree::ErrorCodes::Address::CountryCodeNumericIsNotAccepted)
    end

    it "returns errors if custom_fields are not registered" do
      result = Braintree::Customer.create(
        :first_name => "Jack",
        :last_name => "Kennedy",
        :custom_fields => {
          :spouse_name => "Jacqueline"
        },
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:customer).on(:custom_fields)[0].message).to eq("Custom field is invalid: spouse_name.")
    end

    context "client API" do
      it "can create a customer with a payment method nonce" do
        nonce = nonce_for_new_payment_method(
          :credit_card => {
            :number => "4111111111111111",
            :expiration_month => "11",
            :expiration_year => "2099",
          },
          :share => true,
        )

        result = Braintree::Customer.create(
          :credit_card => {
            :payment_method_nonce => nonce
          },
        )

        expect(result.success?).to eq(true)
        expect(result.customer.credit_cards.first.bin).to eq("411111")
        expect(result.customer.credit_cards.first.last_4).to eq("1111")
      end
    end

    it "can create a customer with an apple pay payment method" do
      result = Braintree::Customer.create(:payment_method_nonce => Braintree::Test::Nonce::ApplePayVisa)

      expect(result.success?).to eq(true)
      expect(result.customer.payment_methods).not_to be_empty
      expect(result.customer.payment_methods.first.token).not_to be_nil
    end

    it "can create a customer with an unknown payment method" do
      result = Braintree::Customer.create(:payment_method_nonce => Braintree::Test::Nonce::AbstractTransactable)

      expect(result.success?).to eq(true)
    end

    context "verification_account_type" do
      it "verifies card with account_type debit" do
        nonce = nonce_for_new_payment_method(
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Hiper,
            :expiration_month => "11",
            :expiration_year => "2099",
          },
        )
        result = Braintree::Customer.create(
          :payment_method_nonce => nonce,
          :credit_card => {
            :options => {
              :verify_card => true,
              :verification_merchant_account_id => SpecHelper::HiperBRLMerchantAccountId,
              :verification_account_type => "debit",
            }
          },
        )

        expect(result).to be_success
      end

      it "verifies card with account_type credit" do
        nonce = nonce_for_new_payment_method(
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Hiper,
            :expiration_month => "11",
            :expiration_year => "2099",
          },
        )
        result = Braintree::Customer.create(
          :payment_method_nonce => nonce,
          :credit_card => {
            :options => {
              :verify_card => true,
              :verification_merchant_account_id => SpecHelper::HiperBRLMerchantAccountId,
              :verification_account_type => "credit",
            }
          },
        )

        expect(result).to be_success
      end

      it "errors with invalid account_type" do
        nonce = nonce_for_new_payment_method(
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Hiper,
            :expiration_month => "11",
            :expiration_year => "2099",
          },
        )
        result = Braintree::Customer.create(
          :payment_method_nonce => nonce,
          :credit_card => {
            :options => {
              :verify_card => true,
              :verification_merchant_account_id => SpecHelper::HiperBRLMerchantAccountId,
              :verification_account_type => "ach",
            }
          },
        )

        expect(result).to_not be_success
        expect(result.errors.for(:customer).for(:credit_card).for(:options).on(:verification_account_type)[0].code).to eq Braintree::ErrorCodes::CreditCard::VerificationAccountTypeIsInvalid
      end

      it "errors when account_type not supported by merchant" do
        nonce = nonce_for_new_payment_method(
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_month => "11",
            :expiration_year => "2099",
          },
        )
        result = Braintree::Customer.create(
          :payment_method_nonce => nonce,
          :credit_card => {
            :options => {
              :verify_card => true,
              :verification_account_type => "credit",
            }
          },
        )

        expect(result).to_not be_success
        expect(result.errors.for(:customer).for(:credit_card).for(:options).on(:verification_account_type)[0].code).to eq Braintree::ErrorCodes::CreditCard::VerificationAccountTypeNotSupported
      end
    end
  end

  describe "self.create!" do
    it "returns the customer if successful" do
      customer = Braintree::Customer.create!(
        :first_name => "Jim",
        :last_name => "Smith",
      )
      expect(customer.id).to match(/\d+/)
      expect(customer.first_name).to eq("Jim")
      expect(customer.last_name).to eq("Smith")
    end

    it "can create without any attributes" do
      customer = Braintree::Customer.create!
      expect(customer.id).to match(/\d+/)
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
        },
      )
      result = Braintree::Customer.credit(customer.id, :amount => "100.00")
      expect(result.success?).to eq(true)
      expect(result.transaction.amount).to eq(BigDecimal("100.00"))
      expect(result.transaction.type).to eq("credit")
      expect(result.transaction.customer_details.id).to eq(customer.id)
      expect(result.transaction.credit_card_details.token).to eq(customer.credit_cards[0].token)
      expect(result.transaction.credit_card_details.bin).to eq(Braintree::Test::CreditCardNumbers::Visa[0, 6])
      expect(result.transaction.credit_card_details.last_4).to eq(Braintree::Test::CreditCardNumbers::Visa[-4..-1])
      expect(result.transaction.credit_card_details.expiration_date).to eq("05/2010")
    end
  end

  describe "self.credit!" do
    it "creates a credit transaction for given customer id, returning a result object" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        },
      )
      transaction = Braintree::Customer.credit!(customer.id, :amount => "100.00")
      expect(transaction.amount).to eq(BigDecimal("100.00"))
      expect(transaction.type).to eq("credit")
      expect(transaction.customer_details.id).to eq(customer.id)
      expect(transaction.credit_card_details.token).to eq(customer.credit_cards[0].token)
      expect(transaction.credit_card_details.bin).to eq(Braintree::Test::CreditCardNumbers::Visa[0, 6])
      expect(transaction.credit_card_details.last_4).to eq(Braintree::Test::CreditCardNumbers::Visa[-4..-1])
      expect(transaction.credit_card_details.expiration_date).to eq("05/2010")
    end
  end

  describe "self.sale" do
    it "creates a sale transaction for given customer id, returning a result object" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        },
      )
      result = Braintree::Customer.sale(customer.id, :amount => "100.00")
      expect(result.success?).to eq(true)
      expect(result.transaction.amount).to eq(BigDecimal("100.00"))
      expect(result.transaction.type).to eq("sale")
      expect(result.transaction.customer_details.id).to eq(customer.id)
      expect(result.transaction.credit_card_details.token).to eq(customer.credit_cards[0].token)
      expect(result.transaction.credit_card_details.bin).to eq(Braintree::Test::CreditCardNumbers::Visa[0, 6])
      expect(result.transaction.credit_card_details.last_4).to eq(Braintree::Test::CreditCardNumbers::Visa[-4..-1])
      expect(result.transaction.credit_card_details.expiration_date).to eq("05/2010")
    end
  end

  describe "self.sale!" do
    it "creates a sale transaction for given customer id, returning the transaction" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        },
      )
      transaction = Braintree::Customer.sale!(customer.id, :amount => "100.00")
      expect(transaction.amount).to eq(BigDecimal("100.00"))
      expect(transaction.type).to eq("sale")
      expect(transaction.customer_details.id).to eq(customer.id)
      expect(transaction.credit_card_details.token).to eq(customer.credit_cards[0].token)
      expect(transaction.credit_card_details.bin).to eq(Braintree::Test::CreditCardNumbers::Visa[0, 6])
      expect(transaction.credit_card_details.last_4).to eq(Braintree::Test::CreditCardNumbers::Visa[-4..-1])
      expect(transaction.credit_card_details.expiration_date).to eq("05/2010")
    end
  end

  describe "self.transactions" do
    it "finds transactions for the given customer id" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        },
      )
      transaction = Braintree::Customer.sale!(customer.id, :amount => "100.00")
      collection = Braintree::Customer.transactions(customer.id)
      expect(collection.first).to eq(transaction)
    end
  end

  describe "credit" do
    it "creates a credit transaction using the customer, returning a result object" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        },
      )
      result = customer.credit(
        :amount => "100.00",
      )
      expect(result.success?).to eq(true)
      expect(result.transaction.amount).to eq(BigDecimal("100.00"))
      expect(result.transaction.type).to eq("credit")
      expect(result.transaction.customer_details.id).to eq(customer.id)
      expect(result.transaction.credit_card_details.token).to eq(customer.credit_cards[0].token)
      expect(result.transaction.credit_card_details.bin).to eq(Braintree::Test::CreditCardNumbers::Visa[0, 6])
      expect(result.transaction.credit_card_details.last_4).to eq(Braintree::Test::CreditCardNumbers::Visa[-4..-1])
      expect(result.transaction.credit_card_details.expiration_date).to eq("05/2010")
    end
  end

  describe "credit!" do
    it "returns the created credit tranaction if valid" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        },
      )
      transaction = customer.credit!(:amount => "100.00")
      expect(transaction.amount).to eq(BigDecimal("100.00"))
      expect(transaction.type).to eq("credit")
      expect(transaction.customer_details.id).to eq(customer.id)
      expect(transaction.credit_card_details.token).to eq(customer.credit_cards[0].token)
      expect(transaction.credit_card_details.bin).to eq(Braintree::Test::CreditCardNumbers::Visa[0, 6])
      expect(transaction.credit_card_details.last_4).to eq(Braintree::Test::CreditCardNumbers::Visa[-4..-1])
      expect(transaction.credit_card_details.expiration_date).to eq("05/2010")
    end
  end

  describe "delete" do
    it "deletes the customer" do
     result = Braintree::Customer.create(
        :first_name => "Joe",
        :last_name => "Cool",
      )
      expect(result.success?).to eq(true)

      customer = result.customer
      expect(customer.delete.success?).to eq(true)
      expect do
        Braintree::Customer.find(customer.id)
      end.to raise_error(Braintree::NotFoundError)
    end
  end


  describe "self.find" do
    it "finds the customer with the given id" do
      result = Braintree::Customer.create(
        :first_name => "Joe",
        :last_name => "Cool",
      )
      expect(result.success?).to eq(true)

      customer = Braintree::Customer.find(result.customer.id)
      expect(customer.id).to eq(result.customer.id)
      expect(customer.graphql_id).not_to be_nil
      expect(customer.first_name).to eq("Joe")
      expect(customer.last_name).to eq("Cool")
    end

    it "returns associated subscriptions" do
      customer = Braintree::Customer.create.customer
      credit_card = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2012",
      ).credit_card

      subscription = Braintree::Subscription.create(
        :payment_method_token => credit_card.token,
        :plan_id => "integration_trialless_plan",
        :price => "1.00",
      ).subscription

      found_customer = Braintree::Customer.find(customer.id)
      expect(found_customer.credit_cards.first.subscriptions.first.id).to eq(subscription.id)
      expect(found_customer.credit_cards.first.subscriptions.first.plan_id).to eq("integration_trialless_plan")
      expect(found_customer.credit_cards.first.subscriptions.first.payment_method_token).to eq(credit_card.token)
      expect(found_customer.credit_cards.first.subscriptions.first.price).to eq(BigDecimal("1.00"))
    end

    context "when given an association filter id" do
      it "filters out all filterable associations" do
        customer = Braintree::Customer.create(
          :custom_fields => {
            :store_me => "custom value"
          },
        ).customer
        credit_card = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2012",
          :billing_address => {
            :street_address => "1 E Main St",
            :locality => "Chicago",
            :region => "Illinois",
            :postal_code => "60622",
            :country_name => "United States of America"
          },
        ).credit_card

        Braintree::Subscription.create(
          :payment_method_token => credit_card.token,
          :plan_id => "integration_trialless_plan",
          :price => "1.00",
        )

        found_customer = Braintree::Customer.find(customer.id, {
          :association_filter_id => "customernoassociations"
        })
        expect(found_customer.credit_cards.length).to eq(0)
        expect(found_customer.payment_methods.length).to eq(0)
        expect(found_customer.addresses.length).to eq(0)
        expect(found_customer.custom_fields).to eq({})
      end

      it "filters out nested filterable associations" do
        customer = Braintree::Customer.create(
          :custom_fields => {
            :store_me => "custom value"
          },
        ).customer
        credit_card = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2012",
          :billing_address => {
            :street_address => "1 E Main St",
            :locality => "Chicago",
            :region => "Illinois",
            :postal_code => "60622",
            :country_name => "United States of America"
          },
        ).credit_card

        Braintree::Subscription.create(
          :payment_method_token => credit_card.token,
          :plan_id => "integration_trialless_plan",
          :price => "1.00",
        )

        found_customer = Braintree::Customer.find(customer.id, {
         :association_filter_id =>  "customertoplevelassociations"
        })

        expect(found_customer.credit_cards.length).to eq(1)
        expect(found_customer.credit_cards.first.subscriptions.length).to eq(0)
        expect(found_customer.payment_methods.length).to eq(1)
        expect(found_customer.payment_methods.first.subscriptions.length).to eq(0)
        expect(found_customer.addresses.length).to eq(1)
        expect(found_customer.custom_fields.length).to eq(1)
      end
    end

    it "returns associated ApplePayCards" do
      result = Braintree::Customer.create(
        :payment_method_nonce => Braintree::Test::Nonce::ApplePayAmEx,
      )
      expect(result.success?).to eq(true)

      found_customer = Braintree::Customer.find(result.customer.id)
      expect(found_customer.apple_pay_cards).not_to be_nil
      apple_pay_card = found_customer.apple_pay_cards.first
      expect(apple_pay_card).to be_a Braintree::ApplePayCard
      expect(apple_pay_card.token).not_to be_nil
      expect(apple_pay_card.expiration_year).not_to be_nil
      expect(apple_pay_card.payment_instrument_name).to eq("AmEx 41002")
      expect(apple_pay_card.commercial).not_to be_nil
      expect(apple_pay_card.country_of_issuance).not_to be_nil
      expect(apple_pay_card.debit).not_to be_nil
      expect(apple_pay_card.durbin_regulated).not_to be_nil
      expect(apple_pay_card.healthcare).not_to be_nil
      expect(apple_pay_card.issuing_bank).not_to be_nil
      expect(apple_pay_card.payroll).not_to be_nil
      expect(apple_pay_card.prepaid).not_to be_nil
      expect(apple_pay_card.product_id).not_to be_nil
    end

    it "returns associated google pay proxy cards" do
      result = Braintree::Customer.create(
        :payment_method_nonce => Braintree::Test::Nonce::GooglePayDiscover,
      )
      expect(result.success?).to eq(true)

      found_customer = Braintree::Customer.find(result.customer.id)
      expect(found_customer.google_pay_cards.size).to eq(1)
      expect(found_customer.payment_methods.size).to eq(1)
      google_pay_card = found_customer.google_pay_cards.first
      expect(google_pay_card).to be_a Braintree::GooglePayCard
      expect(google_pay_card.token).not_to be_nil
      expect(google_pay_card.expiration_year).not_to be_nil
      expect(google_pay_card.is_network_tokenized?).to eq(false)
      expect(google_pay_card.commercial).not_to be_nil
      expect(google_pay_card.country_of_issuance).not_to be_nil
      expect(google_pay_card.debit).not_to be_nil
      expect(google_pay_card.durbin_regulated).not_to be_nil
      expect(google_pay_card.healthcare).not_to be_nil
      expect(google_pay_card.issuing_bank).not_to be_nil
      expect(google_pay_card.payroll).not_to be_nil
      expect(google_pay_card.prepaid).not_to be_nil
      expect(google_pay_card.product_id).not_to be_nil
    end

    it "returns associated google pay network tokens" do
      result = Braintree::Customer.create(
        :payment_method_nonce => Braintree::Test::Nonce::GooglePayMasterCard,
      )
      expect(result.success?).to eq(true)

      found_customer = Braintree::Customer.find(result.customer.id)
      expect(found_customer.google_pay_cards.size).to eq(1)
      expect(found_customer.payment_methods.size).to eq(1)
      google_pay_card = found_customer.google_pay_cards.first
      expect(google_pay_card).to be_a Braintree::GooglePayCard
      expect(google_pay_card.token).not_to be_nil
      expect(google_pay_card.expiration_year).not_to be_nil
      expect(google_pay_card.is_network_tokenized?).to eq(true)
      expect(google_pay_card.commercial).not_to be_nil
      expect(google_pay_card.country_of_issuance).not_to be_nil
      expect(google_pay_card.debit).not_to be_nil
      expect(google_pay_card.durbin_regulated).not_to be_nil
      expect(google_pay_card.healthcare).not_to be_nil
      expect(google_pay_card.issuing_bank).not_to be_nil
      expect(google_pay_card.payroll).not_to be_nil
      expect(google_pay_card.prepaid).not_to be_nil
      expect(google_pay_card.product_id).not_to be_nil
    end

    it "returns associated venmo accounts" do
      result = Braintree::Customer.create(
        :payment_method_nonce => Braintree::Test::Nonce::VenmoAccount,
      )
      expect(result.success?).to eq(true)

      found_customer = Braintree::Customer.find(result.customer.id)
      expect(found_customer.venmo_accounts.size).to eq(1)
      expect(found_customer.payment_methods.size).to eq(1)
      venmo_account = found_customer.venmo_accounts.first
      expect(venmo_account).to be_a Braintree::VenmoAccount
      expect(venmo_account.token).not_to be_nil
      expect(venmo_account.username).not_to be_nil
    end

    xit "returns associated us bank accounts" do
      result = Braintree::Customer.create(
        :payment_method_nonce => generate_non_plaid_us_bank_account_nonce,
        :credit_card => {
          :options => {
            :verification_merchant_account_id => SpecHelper::UsBankMerchantAccountId,
          }
        },
      )
      expect(result).to be_success

      found_customer = Braintree::Customer.find(result.customer.id)
      expect(found_customer.us_bank_accounts.size).to eq(1)
      expect(found_customer.payment_methods.size).to eq(1)

      us_bank_account = found_customer.us_bank_accounts.first
      expect(us_bank_account).to be_a(Braintree::UsBankAccount)
      expect(us_bank_account.routing_number).to eq("021000021")
      expect(us_bank_account.last_4).to eq("0000")
      expect(us_bank_account.account_type).to eq("checking")
      expect(us_bank_account.account_holder_name).to eq("John Doe")
      expect(us_bank_account.bank_name).to match(/CHASE/)
    end

    it "works for a blank customer" do
      created_customer = Braintree::Customer.create!
      found_customer = Braintree::Customer.find(created_customer.id)
      expect(found_customer.id).to eq(created_customer.id)
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
      it "updates the credit card with three_d_secure pass thru params" do
        customer = Braintree::Customer.create!(
          :first_name => "Joe",
          :last_name => "Cool",
        )
        result = Braintree::Customer.update(
          customer.id,
          :first_name => "Mr. Joe",
          :last_name => "Super Cool",
          :custom_fields => {
            :store_me => "a value"
          },
          :credit_card => {
            :number => 4111111111111111,
            :expiration_date => "05/2060",
            :three_d_secure_pass_thru => {
              :eci_flag => "05",
              :cavv => "some_cavv",
              :xid => "some_xid",
              :three_d_secure_version => "1.0.2",
              :authentication_response => "Y",
              :directory_response => "Y",
              :cavv_algorithm => "2",
              :ds_transaction_id => "some_ds_transaction_id",
            },
            :options => {:verify_card => true},
          },
        )
        expect(result.success?).to eq(true)
        expect(result.customer.id).to eq(customer.id)
        expect(result.customer.first_name).to eq("Mr. Joe")
        expect(result.customer.last_name).to eq("Super Cool")
        expect(result.customer.custom_fields[:store_me]).to eq("a value")
      end

      it "validates the presence of three_d_secure_version while passing three_d_secure_pass_thru in update" do
        customer = Braintree::Customer.create!(
          :first_name => "Joe",
          :last_name => "Cool",
        )
        result = Braintree::Customer.update(
          customer.id,
          :first_name => "Mr. Joe",
          :last_name => "Super Cool",
          :custom_fields => {
            :store_me => "a value"
          },
          :credit_card => {
            :number => 4111111111111111,
            :expiration_date => "05/2060",
            :three_d_secure_pass_thru => {
              :eci_flag => "05",
              :cavv => "some_cavv",
              :xid => "some_xid",
              :authentication_response => "Y",
              :directory_response => "Y",
              :cavv_algorithm => "2",
              :ds_transaction_id => "some_ds_transaction_id",
            },
            options: {:verify_card => true}
          },
        )
        expect(result).to_not be_success
        error = result.errors.for(:verification).first
        expect(error.code).to eq(Braintree::ErrorCodes::Verification::ThreeDSecurePassThru::ThreeDSecureVersionIsRequired)
        expect(error.message).to eq("ThreeDSecureVersion is required.")
      end

    it "updates the customer with the given id if successful" do
      customer = Braintree::Customer.create!(
        :first_name => "Joe",
        :last_name => "Cool",
      )
      result = Braintree::Customer.update(
        customer.id,
        :first_name => "Mr. Joe",
        :last_name => "Super Cool",
        :custom_fields => {
          :store_me => "a value"
        },
      )
      expect(result.success?).to eq(true)
      expect(result.customer.id).to eq(customer.id)
      expect(result.customer.first_name).to eq("Mr. Joe")
      expect(result.customer.last_name).to eq("Super Cool")
      expect(result.customer.custom_fields[:store_me]).to eq("a value")
    end

    it "does not update customer with duplicate payment method if fail_on_payment_method option set" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => 4111111111111111,
          :expiration_date => "05/2010",
        },
      )
      result = Braintree::Customer.update(
        customer.id,
        :credit_card => {
          :number => 4111111111111111,
          :expiration_date => "05/2010",
          :options=> {
            :fail_on_duplicate_payment_method => true
          }
        },
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:customer).for(:credit_card).on(:number)[0].message).to eq("Duplicate card exists in the vault.")
    end

    it "updates the default payment method" do
      customer = Braintree::Customer.create!(
        :first_name => "Joe",
        :last_name => "Brown",
      )

      token1 = random_payment_method_token

      Braintree::PaymentMethod.create(
        :customer_id => customer.id,
        :payment_method_nonce => Braintree::Test::Nonce::TransactableVisa,
        :token => token1,
      )

      payment_method1 = Braintree::PaymentMethod.find(token1)
      expect(payment_method1).to be_default

      token2 = random_payment_method_token

      Braintree::PaymentMethod.create(
        :customer_id => customer.id,
        :payment_method_nonce => Braintree::Test::Nonce::TransactableMasterCard,
        :token => token2,
      )

      Braintree::Customer.update(customer.id,
        :default_payment_method_token => token2,
      )

      payment_method2 = Braintree::PaymentMethod.find(token2)
      expect(payment_method2).to be_default
    end

    it "updates the default payment method in the options" do
      customer = Braintree::Customer.create!(
        :first_name => "Joe",
        :last_name => "Brown",
      )

      token1 = random_payment_method_token

      Braintree::PaymentMethod.create(
        :customer_id => customer.id,
        :payment_method_nonce => Braintree::Test::Nonce::TransactableVisa,
        :token => token1,
      )

      payment_method1 = Braintree::PaymentMethod.find(token1)
      expect(payment_method1).to be_default

      token2 = random_payment_method_token

      Braintree::PaymentMethod.create(
        :customer_id => customer.id,
        :payment_method_nonce => Braintree::Test::Nonce::TransactableMasterCard,
        :token => token2,
      )

      Braintree::Customer.update(customer.id,
        :credit_card => {
          :options => {
            :update_existing_token => token2,
            :make_default => true
          }
        },
      )

      payment_method2 = Braintree::PaymentMethod.find(token2)
      expect(payment_method2).to be_default
    end

    it "can use any country code" do
      customer = Braintree::Customer.create!(
        :first_name => "Alex",
        :last_name => "Matterson",
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
        },
      )
      expect(result.success?).to eq(true)
      expect(result.customer.addresses[0].country_name).to eq("Fiji")
      expect(result.customer.addresses[0].country_code_alpha2).to eq("FJ")
      expect(result.customer.addresses[0].country_code_alpha3).to eq("FJI")
      expect(result.customer.addresses[0].country_code_numeric).to eq("242")
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
        },
      )

      result = Braintree::Customer.update(
        customer.id,
        :first_name => "New Joe",
        :credit_card => {
          :cardholder_name => "New Joe Cardholder",
          :options => {:update_existing_token => customer.credit_cards.first.token},
          :billing_address => {
            :last_name => "Cool",
            :postal_code => "60666",
            :options => {:update_existing => true}
          }
        },
      )
      expect(result.success?).to eq(true)
      expect(result.customer.id).to eq(customer.id)
      expect(result.customer.first_name).to eq("New Joe")

      expect(result.customer.credit_cards.size).to eq(1)
      credit_card = result.customer.credit_cards.first
      expect(credit_card.bin).to eq(Braintree::Test::CreditCardNumbers::Visa.slice(0, 6))
      expect(credit_card.cardholder_name).to eq("New Joe Cardholder")

      expect(credit_card.billing_address.first_name).to eq("Joe")
      expect(credit_card.billing_address.last_name).to eq("Cool")
      expect(credit_card.billing_address.postal_code).to eq("60666")
    end

    it "can update the customer and verify_card with a specific verification_amount" do
      customer = Braintree::Customer.create!(
        :first_name => "Joe",
      )

      result = Braintree::Customer.update(
        customer.id,
        :first_name => "New Joe",
        :credit_card => {
          :cardholder_name => "New Joe Cardholder",
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "12/2009",
          :options => {:verify_card => true, :verification_amount => "2.00"}
        },
      )
      expect(result.success?).to eq(true)
    end

    it "includes risk data when skip_advanced_fraud_checking is false" do
      with_fraud_protection_enterprise_merchant do
        customer = Braintree::Customer.create!(
          :first_name => "Joe",
        )

        updated_result = Braintree::Customer.update(
          customer.id,
          :credit_card => {
            :cardholder_name => "New Joe Cardholder",
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/2009",
            :options => {
              :skip_advanced_fraud_checking => false,
              :verify_card => true,
            },
          },
        )

        expect(updated_result).to be_success
        verification = updated_result.customer.credit_cards.first.verification
        expect(verification.risk_data).not_to be_nil
      end
    end

    it "does not include risk data when skip_advanced_fraud_checking is true" do
      with_fraud_protection_enterprise_merchant do
        customer = Braintree::Customer.create!(
          :first_name => "Joe",
        )

        updated_result = Braintree::Customer.update(
          customer.id,
          :credit_card => {
            :cardholder_name => "New Joe Cardholder",
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/2009",
            :options => {
              :skip_advanced_fraud_checking => true,
              :verify_card => true,
            },
          },
        )

        expect(updated_result).to be_success
        verification = updated_result.customer.credit_cards.first.verification
        expect(verification.risk_data).to be_nil
      end
    end

    it "can update a tax_identifier" do
      customer = Braintree::Customer.create!(
        :tax_identifiers => [
          {:country_code => "US", :identifier => "987654321"},
          {:country_code => "CL", :identifier => "123456789"}
        ],
      )

      result = Braintree::Customer.update(
        customer.id,
        :tax_identifiers => [{:country_code => "US", :identifier => "567891234"}],
      )
      expect(result.success?).to eq(true)
    end

    it "validates presence of three_d_secure_version in 3ds pass thru params" do
      result = Braintree::Customer.create(
        :payment_method_nonce => Braintree::Test::Nonce::ThreeDSecureVisaFullAuthentication,
        :credit_card => {
          :three_d_secure_pass_thru => {
            :eci_flag => "05",
            :cavv => "some_cavv",
            :xid => "some_xid",
            :three_d_secure_version => "xx",
            :authentication_response => "Y",
            :directory_response => "Y",
            :cavv_algorithm => "2",
            :ds_transaction_id => "some_ds_transaction_id",
          },
          :options => {:verify_card => true}
        },
      )

      expect(result).not_to be_success
      error = result.errors.for(:verification).first
      expect(error.code).to eq(Braintree::ErrorCodes::Verification::ThreeDSecurePassThru::ThreeDSecureVersionIsInvalid)
      expect(error.message).to eq("The version of 3D Secure authentication must be composed only of digits and separated by periods (e.g. `1.0.2`).")
    end

    it "accepts three_d_secure pass thru params in the request" do
      result = Braintree::Customer.create(
        :payment_method_nonce => Braintree::Test::Nonce::ThreeDSecureVisaFullAuthentication,
        :credit_card => {
          :three_d_secure_pass_thru => {
            :eci_flag => "05",
            :cavv => "some_cavv",
            :xid => "some_xid",
            :three_d_secure_version => "2.2.1",
            :authentication_response => "Y",
            :directory_response => "Y",
            :cavv_algorithm => "2",
            :ds_transaction_id => "some_ds_transaction_id",
          },
          :options => {:verify_card => true}
        },
      )

      expect(result).to be_success
    end

    it "returns 3DS info on cc verification" do
      result = Braintree::Customer.create(
        :payment_method_nonce => Braintree::Test::Nonce::ThreeDSecureVisaFullAuthentication,
        :credit_card => {
          :options => {:verify_card => true}
        },
      )
      expect(result.success?).to eq(true)

      three_d_secure_info = result.customer.payment_methods.first.verification.three_d_secure_info
      expect(three_d_secure_info.enrolled).to eq("Y")
      expect(three_d_secure_info).to be_liability_shifted
      expect(three_d_secure_info).to be_liability_shift_possible
      expect(three_d_secure_info.status).to eq("authenticate_successful")
      expect(three_d_secure_info.cavv).to eq("cavv_value")
      expect(three_d_secure_info.xid).to eq("xid_value")
      expect(three_d_secure_info.eci_flag).to eq("05")
      expect(three_d_secure_info.three_d_secure_version).to eq("1.0.2")
      expect(three_d_secure_info.ds_transaction_id).to eq(nil)
    end

    it "can update the nested billing address with billing_address_id" do
      customer = Braintree::Customer.create!

      address = Braintree::Address.create!(
        :customer_id => customer.id,
        :first_name => "John",
        :last_name => "Doe",
      )

      customer = Braintree::Customer.update(
        customer.id,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "12/2009",
          :billing_address_id => address.id
        },
      ).customer

      billing_address = customer.credit_cards.first.billing_address
      expect(billing_address.id).to eq(address.id)
      expect(billing_address.first_name).to eq("John")
      expect(billing_address.last_name).to eq("Doe")
    end

    it "returns an error response if invalid" do
      customer = Braintree::Customer.create!(:email => "valid@email.com")
      result = Braintree::Customer.update(
        customer.id,
        :email => "@invalid.com",
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:customer).on(:email)[0].message).to eq("Email is an invalid format.")
    end

    context "verification_currency_iso_code" do
      it "can update the customer after validating verification_currency_iso_code" do
        customer = Braintree::Customer.create!(
          :first_name => "Joe",
        )

        result = Braintree::Customer.update(
          customer.id,
          :first_name => "New Joe",
          :credit_card => {
            :cardholder_name => "New Joe Cardholder",
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/2009",
            :options => {:verify_card => true, :verification_currency_iso_code => "USD"}
          },
        )
        expect(result.success?).to eq(true)
        result.customer.credit_cards[0].verification.currency_iso_code == "USD"
      end

      it "can update the customer after validating verification_currency_iso_code against the given verification_merchant_account_id" do
        customer = Braintree::Customer.create!(
          :first_name => "Joe",
        )

        result = Braintree::Customer.update(
          customer.id,
          :first_name => "New Joe",
          :credit_card => {
            :cardholder_name => "New Joe Cardholder",
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/2009",
            :options => {:verify_card => true, :verification_merchant_account_id => SpecHelper::NonDefaultMerchantAccountId, :verification_currency_iso_code => "USD"}
          },
        )
        expect(result.success?).to eq(true)
        result.customer.credit_cards[0].verification.currency_iso_code == "USD"
        result.customer.credit_cards[0].verification.merchant_account_id == SpecHelper::NonDefaultMerchantAccountId
      end

      it "throws error due to verification_currency_iso_code not matching against the currency configured in default merchant account" do
        customer = Braintree::Customer.create!(
          :first_name => "Joe",
        )

        result = Braintree::Customer.update(
          customer.id,
          :first_name => "New Joe",
          :credit_card => {
            :cardholder_name => "New Joe Cardholder",
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/2009",
            :options => {:verify_card => true, :verification_currency_iso_code => "GBP"}
          },
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:customer).for(:credit_card).for(:options).on(:verification_currency_iso_code)[0].code).to eq Braintree::ErrorCodes::CreditCard::CurrencyCodeNotSupportedByMerchantAccount

      end

      it "throws error due to verification_currency_iso_code not matching against the currency configured in the given verification merchant account" do
        customer = Braintree::Customer.create!(
          :first_name => "Joe",
        )

        result = Braintree::Customer.update(
          customer.id,
          :first_name => "New Joe",
          :credit_card => {
            :cardholder_name => "New Joe Cardholder",
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/2009",
            :options => {:verify_card => true, :verification_merchant_account_id => SpecHelper::NonDefaultMerchantAccountId, :verification_currency_iso_code => "GBP"}
          },
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:customer).for(:credit_card).for(:options).on(:verification_currency_iso_code)[0].code).to eq Braintree::ErrorCodes::CreditCard::CurrencyCodeNotSupportedByMerchantAccount

      end
    end

    context "verification_account_type" do
      it "updates the credit card with account_type credit" do
        customer = Braintree::Customer.create!
        update_result = Braintree::Customer.update(
          customer.id,
          :credit_card => {
            :cardholder_name => "New Holder",
            :cvv => "456",
            :number => Braintree::Test::CreditCardNumbers::Hiper,
            :expiration_date => "06/2013",
            :options => {
              :verify_card => true,
              :verification_merchant_account_id => SpecHelper::HiperBRLMerchantAccountId,
              :verification_account_type => "credit",
            },
          },
        )
        expect(update_result).to be_success
      end

      it "updates the credit card with account_type debit" do
        customer = Braintree::Customer.create!
        update_result = Braintree::Customer.update(
          customer.id,
          :credit_card => {
            :cardholder_name => "New Holder",
            :cvv => "456",
            :number => Braintree::Test::CreditCardNumbers::Hiper,
            :expiration_date => "06/2013",
            :options => {
              :verify_card => true,
              :verification_merchant_account_id => SpecHelper::HiperBRLMerchantAccountId,
              :verification_account_type => "debit",
            },
          },
        )
        expect(update_result).to be_success
      end
    end
  end

  describe "self.update!" do
    it "returns the updated customer if successful" do
      customer = Braintree::Customer.create!(
        :first_name => "Joe",
        :last_name => "Cool",
      )
      updated_customer = Braintree::Customer.update!(
        customer.id,
        :first_name => "Mr. Joe",
        :last_name => "Super Cool",
      )
      expect(updated_customer.first_name).to eq("Mr. Joe")
      expect(updated_customer.last_name).to eq("Super Cool")
      expect(updated_customer.updated_at.between?(Time.now - 60, Time.now)).to eq(true)
    end

    it "raises an error if unsuccessful" do
      customer = Braintree::Customer.create!(:email => "valid@email.com")
      expect do
        Braintree::Customer.update!(customer.id, :email => "@invalid.com")
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "default_payment_method" do
    it "should return the default credit card for a given customer" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "12/2015",
          :options => {
            :make_default => false
          }
        },
      )

      default_payment_method = Braintree::CreditCard.create!(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::MasterCard,
        :expiration_date => "11/2015",
        :options => {
          :make_default => true
        },
      )

      customer = Braintree::Customer.find(customer.id)

      expect(customer.default_payment_method).to eq(default_payment_method)
    end
  end

  describe "paypal" do
    context "future" do
      it "creates a customer with a future paypal account" do
        result = Braintree::Customer.create(
          :payment_method_nonce => Braintree::Test::Nonce::PayPalBillingAgreement,
        )

        expect(result).to be_success
      end

      it "updates a customer with a future paypal account" do
        customer = Braintree::Customer.create!(
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/2015",
            :options => {
              :make_default => true
            }
          },
        )

        paypal_account_token = "PAYPAL_ACCOUNT_TOKEN_#{rand(36**3).to_s(36)}"
        nonce = nonce_for_paypal_account(
          :consent_code => "PAYPAL_CONSENT_CODE",
          :token => paypal_account_token,
          :options => {
            :make_default => true
          },
        )

        result = Braintree::Customer.update(
          customer.id,
          :payment_method_nonce => nonce,
        )

        expect(result).to be_success
        expect(result.customer.default_payment_method.token).to eq(paypal_account_token)
      end
    end

    context "limited use" do
      it "creates a customer with payment_method_nonce and paypal options" do
        paypal_account_token = "PAYPAL_ACCOUNT_TOKEN_#{rand(36**3).to_s(36)}"
        nonce = nonce_for_paypal_account(
          :consent_code => "PAYPAL_CONSENT_CODE",
          :token => paypal_account_token,
          :options => {
            :make_default => true
          },
        )

        result = Braintree::Customer.create(
          :payment_method_nonce => nonce,
          :options => {
            :paypal => {
              :payee_email => "payee@example.com",
              :order_id => "merchant-order-id",
              :custom_field => "custom merchant field",
              :description => "merchant description",
              :amount => "1.23",
              :shipping => {
                :first_name => "first",
                :last_name => "last",
                :locality => "Austin",
                :postal_code => "78729",
                :street_address => "7700 W Parmer Ln",
                :country_name => "US",
                :region => "TX",
              },
            },
          },
        )

        expect(result).to be_success
      end

      it "updates a customer with payment_method_nonce and paypal options" do
        customer = Braintree::Customer.create!(
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/2015",
            :options => {
              :make_default => true
            }
          },
        )

        paypal_account_token = "PAYPAL_ACCOUNT_TOKEN_#{rand(36**3).to_s(36)}"
        nonce = nonce_for_paypal_account(
          :consent_code => "PAYPAL_CONSENT_CODE",
          :token => paypal_account_token,
          :options => {
            :make_default => true
          },
        )

        result = Braintree::Customer.update(
          customer.id,
          :payment_method_nonce => nonce,
          :options => {
            :paypal => {
              :payee_email => "payee@example.com",
              :order_id => "merchant-order-id",
              :custom_field => "custom merchant field",
              :description => "merchant description",
              :amount => "1.23",
              :shipping => {
                :first_name => "first",
                :last_name => "last",
                :locality => "Austin",
                :postal_code => "78729",
                :street_address => "7700 W Parmer Ln",
                :country_name => "US",
                :region => "TX",
              },
            },
          },
        )

        expect(result).to be_success
        expect(result.customer.default_payment_method.token).to eq(paypal_account_token)
      end
    end

    context "onetime" do
      it "does not create a customer with a onetime paypal account" do
        result = Braintree::Customer.create(
          :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
        )

        expect(result).not_to be_success
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
          },
        )

        paypal_account_token = "PAYPAL_ACCOUNT_TOKEN_#{rand(36**3).to_s(36)}"
        nonce = nonce_for_paypal_account(
          :access_token => "PAYPAL_ACCESS_TOKEN",
          :token => paypal_account_token,
          :options => {
            :make_default => true
          },
        )

        result = Braintree::Customer.update(
          customer.id,
          :payment_method_nonce => nonce,
        )

        expect(result).not_to be_success
        expect(customer.default_payment_method.token).to eq(credit_card_token)
      end
    end
  end
end
