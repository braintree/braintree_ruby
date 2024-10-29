require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::CreditCard do
  describe "self.create" do
    it "throws and ArgumentError if given exipiration_date and any combination of expiration_month and expiration_year" do
      expect do
        Braintree::CreditCard.create :expiration_date => "anything", :expiration_month => "anything"
      end.to raise_error(ArgumentError, "create with both expiration_month and expiration_year or only expiration_date")
    end

    it "adds credit card to an existing customer" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2009",
        :cvv => "100",
      )
      expect(result.success?).to eq(true)
      credit_card = result.credit_card
      expect(credit_card.token).to match(/\A\w{4,}\z/)
      expect(credit_card.bin).to eq(Braintree::Test::CreditCardNumbers::Visa[0, 6])
      expect(credit_card.last_4).to eq(Braintree::Test::CreditCardNumbers::Visa[-4..-1])
      expect(credit_card.expiration_date).to eq("05/2009")
      expect(credit_card.unique_number_identifier).to match(/\A\w{32}\z/)
      expect(credit_card.venmo_sdk?).to eq(false)
      expect(credit_card.image_url).not_to be_nil
    end

    it "supports creation of cards with security params" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2009",
        :cvv => "100",
        :device_data => "device_data",
      )
      expect(result.success?).to eq(true)
    end

    it "can provide expiration month and year separately" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_month => "05",
        :expiration_year => "2012",
      )
      expect(result.success?).to eq(true)
      credit_card = result.credit_card
      expect(credit_card.expiration_month).to eq("05")
      expect(credit_card.expiration_year).to eq("2012")
      expect(credit_card.expiration_date).to eq("05/2012")
    end

    it "can specify the desired token" do
      token = "token_#{rand(10**10)}"
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2009",
        :cvv => "100",
        :token => token,
      )
      expect(result.success?).to eq(true)
      credit_card = result.credit_card
      expect(credit_card.token).to eq(token)
      expect(credit_card.bin).to eq(Braintree::Test::CreditCardNumbers::Visa[0, 6])
      expect(credit_card.last_4).to eq(Braintree::Test::CreditCardNumbers::Visa[-4..-1])
      expect(credit_card.expiration_date).to eq("05/2009")
    end

    it "accepts billing_address_id" do
      customer = Braintree::Customer.create!
      address = Braintree::Address.create!(:customer_id => customer.id, :first_name => "Bobby", :last_name => "Tables")

      credit_card = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::Visa,
        :expiration_date => "05/2009",
        :billing_address_id => address.id,
      ).credit_card

      expect(credit_card.billing_address.id).to eq(address.id)
      expect(credit_card.billing_address.first_name).to eq("Bobby")
      expect(credit_card.billing_address.last_name).to eq("Tables")
    end

    it "accepts empty options hash" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::Visa,
        :expiration_date => "05/2009",
        :options => {},
      )
      expect(result.success?).to eq(true)
    end

    it "verifies the credit card if options[verify_card]=true" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::Visa,
        :expiration_date => "05/2009",
        :options => {:verify_card => true},
      )
      expect(result.success?).to eq(false)
      expect(result.credit_card_verification.status).to eq(Braintree::CreditCardVerification::Status::ProcessorDeclined)
      expect(result.credit_card_verification.processor_response_code).to eq("2000")
      expect(result.credit_card_verification.processor_response_text).to eq("Do Not Honor")
      expect(result.credit_card_verification.cvv_response_code).to eq("I")
      expect(result.credit_card_verification.avs_error_response_code).to eq(nil)
      expect(result.credit_card_verification.avs_postal_code_response_code).to eq("I")
      expect(result.credit_card_verification.avs_street_address_response_code).to eq("I")
    end

    it "allows passing a specific verification amount" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::Visa,
        :expiration_date => "05/2009",
        :options => {:verify_card => true, :verification_amount => "100.00"},
      )
      expect(result.success?).to eq(false)
      expect(result.credit_card_verification.status).to eq(Braintree::CreditCardVerification::Status::ProcessorDeclined)
      expect(result.credit_card_verification.processor_response_code).to eq("2000")
      expect(result.credit_card_verification.processor_response_text).to eq("Do Not Honor")
      expect(result.credit_card_verification.cvv_response_code).to eq("I")
      expect(result.credit_card_verification.avs_error_response_code).to eq(nil)
      expect(result.credit_card_verification.avs_postal_code_response_code).to eq("I")
      expect(result.credit_card_verification.avs_street_address_response_code).to eq("I")
    end

    it "returns risk data on verification on credit_card create" do
      with_fraud_protection_enterprise_merchant do
        customer = Braintree::Customer.create!
        credit_card = Braintree::CreditCard.create!(
          :cardholder_name => "Original Holder",
          :customer_id => customer.id,
          :cvv => "123",
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2020",
          :options => {:verify_card => true},
        )
        verification = credit_card.verification
        expect(verification.risk_data.id).not_to be_nil
        expect(verification.risk_data.decision).not_to be_nil
        expect(verification.risk_data.decision_reasons).not_to be_nil
        expect(verification.risk_data).to respond_to(:device_data_captured)
        expect(verification.risk_data).to respond_to(:fraud_service_provider)
        expect(verification.risk_data).to respond_to(:transaction_risk_score)
      end
    end

    it "includes risk data when skip_advanced_fraud_checking is false" do
      with_fraud_protection_enterprise_merchant do
        customer = Braintree::Customer.create!
        result = Braintree::CreditCard.create(
          :cardholder_name => "Original Holder",
          :customer_id => customer.id,
          :cvv => "123",
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2020",
          :options => {
            :skip_advanced_fraud_checking => false,
            :verify_card => true,
          },
        )

        expect(result).to be_success
        verification = result.credit_card.verification
        expect(verification.risk_data).not_to be_nil
      end
    end

    it "does not include risk data when skip_advanced_fraud_checking is true" do
      with_fraud_protection_enterprise_merchant do
        customer = Braintree::Customer.create!
        result = Braintree::CreditCard.create(
          :cardholder_name => "Original Holder",
          :customer_id => customer.id,
          :cvv => "123",
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2020",
          :options => {
            :skip_advanced_fraud_checking => true,
            :verify_card => true,
          },
        )

        expect(result).to be_success
        verification = result.credit_card.verification
        expect(verification.risk_data).to be_nil
      end
    end

    it "exposes the gateway rejection reason on verification" do
      old_merchant = Braintree::Configuration.merchant_id
      old_public_key = Braintree::Configuration.public_key
      old_private_key = Braintree::Configuration.private_key

      begin
        Braintree::Configuration.merchant_id = "processing_rules_merchant_id"
        Braintree::Configuration.public_key = "processing_rules_public_key"
        Braintree::Configuration.private_key = "processing_rules_private_key"

        customer = Braintree::Customer.create!
        result = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009",
          :cvv => "200",
          :options => {:verify_card => true},
        )
        expect(result.success?).to eq(false)
        expect(result.credit_card_verification.gateway_rejection_reason).to eq(Braintree::CreditCardVerification::GatewayRejectionReason::CVV)
      ensure
        Braintree::Configuration.merchant_id = old_merchant
        Braintree::Configuration.public_key = old_public_key
        Braintree::Configuration.private_key = old_private_key
      end
    end

    it "verifies the credit card if options[verify_card]=true" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::Visa,
        :expiration_date => "05/2009",
        :options => {:verify_card => true, :verification_amount => "1.01"},
      )
      expect(result.success?).to eq(false)
      expect(result.credit_card_verification.status).to eq(Braintree::CreditCardVerification::Status::ProcessorDeclined)
      expect(result.credit_card_verification.processor_response_code).to eq("2000")
      expect(result.credit_card_verification.processor_response_text).to eq("Do Not Honor")
      expect(result.credit_card_verification.cvv_response_code).to eq("I")
      expect(result.credit_card_verification.avs_error_response_code).to eq(nil)
      expect(result.credit_card_verification.avs_postal_code_response_code).to eq("I")
      expect(result.credit_card_verification.avs_street_address_response_code).to eq("I")
    end

    it "allows user to specify merchant account for verification" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::Visa,
        :expiration_date => "05/2009",
        :options => {
          :verify_card => true,
          :verification_merchant_account_id => SpecHelper::NonDefaultMerchantAccountId
        },
      )
      expect(result.success?).to eq(false)
      expect(result.credit_card_verification.merchant_account_id).to eq(SpecHelper::NonDefaultMerchantAccountId)
    end

    it "does not verify the card if options[verify_card]=false" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::Visa,
        :expiration_date => "05/2009",
        :options => {:verify_card => false},
      )
      expect(result.success?).to eq(true)
    end

    it "validates presence of three_d_secure_version in 3ds pass thru params" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :payment_method_nonce => Braintree::Test::Nonce::Transactable,
        :three_d_secure_pass_thru => {
          :eci_flag => "05",
          :cavv => "some_cavv",
          :xid => "some_xid",
          :authentication_response => "Y",
          :directory_response => "Y",
          :cavv_algorithm => "2",
          :ds_transaction_id => "some_ds_transaction_id",
        },
        :options => {:verify_card => true},
      )
      expect(result).not_to be_success
      error = result.errors.for(:verification).first
      expect(error.code).to eq(Braintree::ErrorCodes::Verification::ThreeDSecurePassThru::ThreeDSecureVersionIsRequired)
      expect(error.message).to eq("ThreeDSecureVersion is required.")
    end

    it "accepts three_d_secure pass thru params in the request" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :payment_method_nonce => Braintree::Test::Nonce::Transactable,
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
      )
      expect(result.success?).to eq(true)
    end

    it "returns 3DS info on cc verification" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :payment_method_nonce => Braintree::Test::Nonce::ThreeDSecureVisaFullAuthentication,
        :options => {:verify_card => true},
      )
      expect(result.success?).to eq(true)

      three_d_secure_info = result.credit_card.verification.three_d_secure_info
      expect(three_d_secure_info.status).to eq("authenticate_successful")
      expect(three_d_secure_info).to be_liability_shifted
      expect(three_d_secure_info).to be_liability_shift_possible
      expect(three_d_secure_info.enrolled).to be_a(String)
      expect(three_d_secure_info.cavv).to be_a(String)
      expect(three_d_secure_info.xid).to be_a(String)
      expect(three_d_secure_info.eci_flag).to be_a(String)
      expect(three_d_secure_info.three_d_secure_version).to be_a(String)
      expect(three_d_secure_info.three_d_secure_authentication_id).to be_a(String)
    end

    it "adds credit card with billing address to customer" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::MasterCard,
        :expiration_date => "12/2009",
        :billing_address => {
          :street_address => "123 Abc Way",
          :locality => "Chicago",
          :region => "Illinois",
          :postal_code => "60622"
        },
      )
      expect(result.success?).to eq(true)
      credit_card = result.credit_card
      expect(credit_card.bin).to eq(Braintree::Test::CreditCardNumbers::MasterCard[0, 6])
      expect(credit_card.billing_address.street_address).to eq("123 Abc Way")
    end

    it "adds credit card with billing using country_code" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::MasterCard,
        :expiration_date => "12/2009",
        :billing_address => {
          :country_name => "United States of America",
          :country_code_alpha2 => "US",
          :country_code_alpha3 => "USA",
          :country_code_numeric => "840"
        },
      )
      expect(result.success?).to eq(true)
      credit_card = result.credit_card
      expect(credit_card.billing_address.country_name).to eq("United States of America")
      expect(credit_card.billing_address.country_code_alpha2).to eq("US")
      expect(credit_card.billing_address.country_code_alpha3).to eq("USA")
      expect(credit_card.billing_address.country_code_numeric).to eq("840")
    end

    it "returns an error when given inconsistent country information" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::MasterCard,
        :expiration_date => "12/2009",
        :billing_address => {
          :country_name => "Mexico",
          :country_code_alpha2 => "US"
        },
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:credit_card).for(:billing_address).on(:base).map { |e| e.code }).to include(Braintree::ErrorCodes::Address::InconsistentCountry)
    end

    it "returns an error response if unsuccessful" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "invalid_date",
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:credit_card).on(:expiration_date)[0].message).to eq("Expiration date is invalid.")
    end

    it "can set the default flag" do
      customer = Braintree::Customer.create!
      card1 = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2009",
      ).credit_card
      expect(card1).to be_default

      card2 = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2009",
        :options => {
          :make_default => true
        },
      ).credit_card
      expect(card2).to be_default

      expect(Braintree::CreditCard.find(card1.token)).not_to be_default
    end

    it "can set the network transaction identifier when creating a credit card" do
      customer = Braintree::Customer.create!

      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2009",
        :external_vault => {
          :network_transaction_id => "MCC123456789",
        },
      )

      expect(result.success?).to eq(true)
    end

    context "card type indicators" do
      it "sets the prepaid field if the card is prepaid" do
        customer = Braintree::Customer.create!
        result = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::CardTypeIndicators::Prepaid,
          :expiration_date => "05/2014",
          :options => {:verify_card => true},
        )
        credit_card = result.credit_card
        expect(credit_card.prepaid).to eq(Braintree::CreditCard::Prepaid::Yes)
      end

      it "sets the healthcare field if the card is healthcare" do
        customer = Braintree::Customer.create!
        result = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::CardTypeIndicators::Healthcare,
          :expiration_date => "05/2014",
          :options => {:verify_card => true},
        )
        credit_card = result.credit_card
        expect(credit_card.healthcare).to eq(Braintree::CreditCard::Healthcare::Yes)
        expect(credit_card.product_id).to eq("J3")
      end

      it "sets the durbin regulated field if the card is durbin regulated" do
        customer = Braintree::Customer.create!
        result = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::CardTypeIndicators::DurbinRegulated,
          :expiration_date => "05/2014",
          :options => {:verify_card => true},
        )
        credit_card = result.credit_card
        expect(credit_card.durbin_regulated).to eq(Braintree::CreditCard::DurbinRegulated::Yes)
      end

      it "sets the country of issuance field" do
        customer = Braintree::Customer.create!
        result = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::CardTypeIndicators::CountryOfIssuance,
          :expiration_date => "05/2014",
          :options => {:verify_card => true},
        )
        credit_card = result.credit_card
        expect(credit_card.country_of_issuance).to eq(Braintree::Test::CreditCardDefaults::CountryOfIssuance)
      end

      it "sets the issuing bank field" do
        customer = Braintree::Customer.create!
        result = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::CardTypeIndicators::IssuingBank,
          :expiration_date => "05/2014",
          :options => {:verify_card => true},
        )
        credit_card = result.credit_card
        expect(credit_card.issuing_bank).to eq(Braintree::Test::CreditCardDefaults::IssuingBank)
      end

      it "sets the payroll field if the card is payroll" do
        customer = Braintree::Customer.create!
        result = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::CardTypeIndicators::Payroll,
          :expiration_date => "05/2014",
          :options => {:verify_card => true},
        )
        credit_card = result.credit_card
        expect(credit_card.payroll).to eq(Braintree::CreditCard::Payroll::Yes)
        expect(credit_card.product_id).to eq("MSA")
      end

      it "sets the debit field if the card is debit" do
        customer = Braintree::Customer.create!
        result = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::CardTypeIndicators::Debit,
          :expiration_date => "05/2014",
          :options => {:verify_card => true},
        )
        credit_card = result.credit_card
        expect(credit_card.debit).to eq(Braintree::CreditCard::Debit::Yes)
      end

      it "sets the commercial field if the card is commercial" do
        customer = Braintree::Customer.create!
        result = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::CardTypeIndicators::Commercial,
          :expiration_date => "05/2014",
          :options => {:verify_card => true},
        )
        credit_card = result.credit_card
        expect(credit_card.commercial).to eq(Braintree::CreditCard::Commercial::Yes)
      end

      it "sets negative card type identifiers" do
        customer = Braintree::Customer.create!
        result = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::CardTypeIndicators::No,
          :expiration_date => "05/2014",
          :options => {:verify_card => true},
        )
        credit_card = result.credit_card
        expect(credit_card.prepaid).to eq(Braintree::CreditCard::Prepaid::No)
        expect(credit_card.commercial).to eq(Braintree::CreditCard::Prepaid::No)
        expect(credit_card.payroll).to eq(Braintree::CreditCard::Prepaid::No)
        expect(credit_card.debit).to eq(Braintree::CreditCard::Prepaid::No)
        expect(credit_card.durbin_regulated).to eq(Braintree::CreditCard::Prepaid::No)
        expect(credit_card.healthcare).to eq(Braintree::CreditCard::Prepaid::No)
        expect(credit_card.product_id).to eq("MSB")
      end

      it "doesn't set the card type identifiers for an un-identified card" do
        customer = Braintree::Customer.create!
        result = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::CardTypeIndicators::Unknown,
          :expiration_date => "05/2014",
          :options => {:verify_card => true},
        )
        credit_card = result.credit_card
        expect(credit_card.prepaid).to eq(Braintree::CreditCard::Prepaid::Unknown)
        expect(credit_card.commercial).to eq(Braintree::CreditCard::Prepaid::Unknown)
        expect(credit_card.payroll).to eq(Braintree::CreditCard::Prepaid::Unknown)
        expect(credit_card.debit).to eq(Braintree::CreditCard::Prepaid::Unknown)
        expect(credit_card.durbin_regulated).to eq(Braintree::CreditCard::Prepaid::Unknown)
        expect(credit_card.healthcare).to eq(Braintree::CreditCard::Prepaid::Unknown)
        credit_card.country_of_issuance == Braintree::CreditCard::CountryOfIssuance::Unknown
        credit_card.issuing_bank == Braintree::CreditCard::IssuingBank::Unknown
        credit_card.product_id == Braintree::CreditCard::ProductId::Unknown
      end
    end

    context "client API" do
      it "adds credit card to an existing customer using a payment method nonce" do
        nonce = nonce_for_new_payment_method(
          :credit_card => {
            :number => "4111111111111111",
            :expiration_month => "11",
            :expiration_year => "2099",
          },
          :share => true,
        )
        customer = Braintree::Customer.create!
        result = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :payment_method_nonce => nonce,
        )

        expect(result.success?).to eq(true)
        credit_card = result.credit_card
        expect(credit_card.bin).to eq("411111")
        expect(credit_card.last_4).to eq("1111")
        expect(credit_card.expiration_date).to eq("11/2099")
      end
    end

    context "card_type" do
      it "is set to Elo" do
        customer = Braintree::Customer.create!
        result = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Elo,
          :expiration_date => "10/2020",
        )
        expect(result.success?).to eq(true)
        credit_card = result.credit_card
        expect(credit_card.card_type).to eq(Braintree::CreditCard::CardType::Elo)
      end
    end

    context "verification_account_type" do
      it "verifies card with account_type debit" do
        customer = Braintree::Customer.create!
        result = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Hiper,
          :expiration_month => "11",
          :expiration_year => "2099",
          :options => {
            :verify_card => true,
            :verification_merchant_account_id => SpecHelper::CardProcessorBRLMerchantAccountId,
            :verification_account_type => "debit",
          },
        )

        expect(result).to be_success
      end

      it "verifies card with account_type credit" do
        customer = Braintree::Customer.create!
        result = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Hiper,
          :expiration_month => "11",
          :expiration_year => "2099",
          :options => {
            :verify_card => true,
            :verification_merchant_account_id => SpecHelper::HiperBRLMerchantAccountId,
            :verification_account_type => "credit",
          },
        )

        expect(result).to be_success
      end

      it "errors with invalid account_type" do
        result = Braintree::CreditCard.create(
          :number => Braintree::Test::CreditCardNumbers::Hiper,
          :expiration_month => "11",
          :expiration_year => "2099",
          :options => {
            :verify_card => true,
            :verification_merchant_account_id => SpecHelper::HiperBRLMerchantAccountId,
            :verification_account_type => "ach",
          },
        )

        expect(result).to_not be_success
        expect(result.errors.for(:credit_card).for(:options).on(:verification_account_type)[0].code).to eq Braintree::ErrorCodes::CreditCard::VerificationAccountTypeIsInvalid
      end

      it "errors when account_type not supported by merchant" do
        result = Braintree::CreditCard.create(
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_month => "11",
          :expiration_year => "2099",
          :options => {
            :verify_card => true,
            :verification_account_type => "credit",
          },
        )

        expect(result).to_not be_success
        expect(result.errors.for(:credit_card).for(:options).on(:verification_account_type)[0].code).to eq Braintree::ErrorCodes::CreditCard::VerificationAccountTypeNotSupported
      end
    end
  end

  describe "self.create!" do
    it "returns the credit card if successful" do
      customer = Braintree::Customer.create!
      credit_card = Braintree::CreditCard.create!(
        :customer_id => customer.id,
        :cardholder_name => "Adam Davis",
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2009",
      )
      expect(credit_card.bin).to eq(Braintree::Test::CreditCardNumbers::Visa[0, 6])
      expect(credit_card.cardholder_name).to eq("Adam Davis")
      expect(credit_card.last_4).to eq(Braintree::Test::CreditCardNumbers::Visa[-4..-1])
      expect(credit_card.expiration_date).to eq("05/2009")
    end

    it "raises a ValidationsFailed if unsuccessful" do
      customer = Braintree::Customer.create!
      expect do
        Braintree::CreditCard.create!(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "invalid_date",
        )
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  # NEXT_MAJOR_VERSION remove this test
  # CreditCard.credit has been deprecated in favor of Transaction.credit
  describe "self.credit" do
    it "creates a credit transaction using the payment method token, returning a result object" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        },
      )
      result = Braintree::CreditCard.credit(
        customer.credit_cards[0].token,
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

  describe "self.credit!" do
    it "creates a credit transaction using the payment method token, returning the transaction" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        },
      )
      transaction = Braintree::CreditCard.credit!(
        customer.credit_cards[0].token,
        :amount => "100.00",
      )
      expect(transaction.amount).to eq(BigDecimal("100.00"))
      expect(transaction.type).to eq("credit")
      expect(transaction.customer_details.id).to eq(customer.id)
      expect(transaction.credit_card_details.token).to eq(customer.credit_cards[0].token)
      expect(transaction.credit_card_details.bin).to eq(Braintree::Test::CreditCardNumbers::Visa[0, 6])
      expect(transaction.credit_card_details.last_4).to eq(Braintree::Test::CreditCardNumbers::Visa[-4..-1])
      expect(transaction.credit_card_details.expiration_date).to eq("05/2010")
    end
  end

  describe "self.update" do
    it "updates the credit card" do
      customer = Braintree::Customer.create!
      credit_card = Braintree::CreditCard.create!(
        :cardholder_name => "Original Holder",
        :customer_id => customer.id,
        :cvv => "123",
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2012",
      )
      update_result = Braintree::CreditCard.update(credit_card.token,
        :cardholder_name => "New Holder",
        :cvv => "456",
        :number => Braintree::Test::CreditCardNumbers::MasterCard,
        :expiration_date => "06/2013",
      )
      expect(update_result.success?).to eq(true)
      expect(update_result.credit_card).to eq(credit_card)
      updated_credit_card = update_result.credit_card
      expect(updated_credit_card.bin).to eq(Braintree::Test::CreditCardNumbers::MasterCard[0, 6])
      expect(updated_credit_card.last_4).to eq(Braintree::Test::CreditCardNumbers::MasterCard[-4..-1])
      expect(updated_credit_card.expiration_date).to eq("06/2013")
      expect(updated_credit_card.cardholder_name).to eq("New Holder")
    end

    it "validates presence of three_d_secure_version in 3ds pass thru params" do
      customer = Braintree::Customer.create!
      credit_card = Braintree::CreditCard.create!(
        :cardholder_name => "Original Holder",
        :customer_id => customer.id,
        :cvv => "123",
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2012",
      )
      result = Braintree::CreditCard.update(credit_card.token,
        :payment_method_nonce => Braintree::Test::Nonce::Transactable,
        :three_d_secure_pass_thru => {
          :eci_flag => "05",
          :cavv => "some_cavv",
          :xid => "some_xid",
          :authentication_response => "Y",
          :directory_response => "Y",
          :cavv_algorithm => "2",
          :ds_transaction_id => "some_ds_transaction_id",
        },
        :options => {:verify_card => true},
      )
      expect(result).not_to be_success
      error = result.errors.for(:verification).first
      expect(error.code).to eq(Braintree::ErrorCodes::Verification::ThreeDSecurePassThru::ThreeDSecureVersionIsRequired)
      expect(error.message).to eq("ThreeDSecureVersion is required.")
    end

    it "accepts three_d_secure pass thru params in the request" do
      customer = Braintree::Customer.create!
      credit_card = Braintree::CreditCard.create!(
        :cardholder_name => "Original Holder",
        :customer_id => customer.id,
        :cvv => "123",
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2012",
      )
      result = Braintree::CreditCard.update(credit_card.token,
        :payment_method_nonce => Braintree::Test::Nonce::Transactable,
        :three_d_secure_pass_thru => {
          :eci_flag => "05",
          :cavv => "some_cavv",
          :three_d_secure_version=> "2.1.0",
          :xid => "some_xid",
          :authentication_response => "Y",
          :directory_response => "Y",
          :cavv_algorithm => "2",
          :ds_transaction_id => "some_ds_transaction_id",
        },
        :options => {:verify_card => true},
      )

      expect(result.success?).to eq(true)
    end

    it "includes risk data when skip_advanced_fraud_checking is false" do
      with_fraud_protection_enterprise_merchant do
        customer = Braintree::Customer.create!
        credit_card = Braintree::CreditCard.create!(
          :cardholder_name => "Original Holder",
          :customer_id => customer.id,
          :cvv => "123",
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2020",
        )
        updated_result = Braintree::CreditCard.update(credit_card.token,
          :expiration_date => "05/2021",
          :options => {
            :verify_card => true,
            :skip_advanced_fraud_checking => false,
          },
        )

        expect(updated_result).to be_success
        verification = updated_result.credit_card.verification
        expect(verification.risk_data).not_to be_nil
      end
    end

    it "does not include risk data when skip_advanced_fraud_checking is true" do
      with_fraud_protection_enterprise_merchant do
        customer = Braintree::Customer.create!
        credit_card = Braintree::CreditCard.create!(
          :cardholder_name => "Original Holder",
          :customer_id => customer.id,
          :cvv => "123",
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2020",
        )
        updated_result = Braintree::CreditCard.update(credit_card.token,
          :expiration_date => "05/2021",
          :options => {
            :verify_card => true,
            :skip_advanced_fraud_checking => true,
          },
        )

        expect(updated_result).to be_success
        verification = updated_result.credit_card.verification
        expect(verification.risk_data).to be_nil
      end
    end

    context "billing address" do
      it "creates a new billing address by default" do
        customer = Braintree::Customer.create!
        credit_card = Braintree::CreditCard.create!(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2012",
          :billing_address => {
            :street_address => "123 Nigeria Ave"
          },
        )
        update_result = Braintree::CreditCard.update(credit_card.token,
          :billing_address => {
            :region => "IL"
          },
        )
        expect(update_result.success?).to eq(true)
        updated_credit_card = update_result.credit_card
        expect(updated_credit_card.billing_address.region).to eq("IL")
        expect(updated_credit_card.billing_address.street_address).to eq(nil)
        expect(updated_credit_card.billing_address.id).not_to eq(credit_card.billing_address.id)
      end

      it "updates the billing address if option is specified" do
        customer = Braintree::Customer.create!
        credit_card = Braintree::CreditCard.create!(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2012",
          :billing_address => {
            :street_address => "123 Nigeria Ave"
          },
        )
        update_result = Braintree::CreditCard.update(credit_card.token,
          :billing_address => {
            :region => "IL",
            :options => {:update_existing => true}
          },
        )
        expect(update_result.success?).to eq(true)
        updated_credit_card = update_result.credit_card
        expect(updated_credit_card.billing_address.region).to eq("IL")
        expect(updated_credit_card.billing_address.street_address).to eq("123 Nigeria Ave")
        expect(updated_credit_card.billing_address.id).to eq(credit_card.billing_address.id)
      end

      it "updates the country via codes" do
        customer = Braintree::Customer.create!
        credit_card = Braintree::CreditCard.create!(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2012",
          :billing_address => {
            :street_address => "123 Nigeria Ave"
          },
        )
        update_result = Braintree::CreditCard.update(credit_card.token,
          :billing_address => {
            :country_name => "American Samoa",
            :country_code_alpha2 => "AS",
            :country_code_alpha3 => "ASM",
            :country_code_numeric => "016",
            :options => {:update_existing => true}
          },
        )
        expect(update_result.success?).to eq(true)
        updated_credit_card = update_result.credit_card
        expect(updated_credit_card.billing_address.country_name).to eq("American Samoa")
        expect(updated_credit_card.billing_address.country_code_alpha2).to eq("AS")
        expect(updated_credit_card.billing_address.country_code_alpha3).to eq("ASM")
        expect(updated_credit_card.billing_address.country_code_numeric).to eq("016")
      end
    end

    it "can pass expiration_month and expiration_year" do
      customer = Braintree::Customer.create!
      credit_card = Braintree::CreditCard.create!(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2012",
      )
      update_result = Braintree::CreditCard.update(credit_card.token,
        :number => Braintree::Test::CreditCardNumbers::MasterCard,
        :expiration_month => "07",
        :expiration_year => "2011",
      )
      expect(update_result.success?).to eq(true)
      expect(update_result.credit_card).to eq(credit_card)
      expect(update_result.credit_card.expiration_month).to eq("07")
      expect(update_result.credit_card.expiration_year).to eq("2011")
      expect(update_result.credit_card.expiration_date).to eq("07/2011")
    end

    it "verifies the update if options[verify_card]=true" do
      customer = Braintree::Customer.create!
      credit_card = Braintree::CreditCard.create!(
        :cardholder_name => "Original Holder",
        :customer_id => customer.id,
        :cvv => "123",
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2012",
      )
      update_result = Braintree::CreditCard.update(credit_card.token,
        :cardholder_name => "New Holder",
        :cvv => "456",
        :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::MasterCard,
        :expiration_date => "06/2013",
        :options => {:verify_card => true},
      )
      expect(update_result.success?).to eq(false)
      expect(update_result.credit_card_verification.status).to eq(Braintree::CreditCardVerification::Status::ProcessorDeclined)
      expect(update_result.credit_card_verification.gateway_rejection_reason).to be_nil
    end

    it "can update the billing address" do
      customer = Braintree::Customer.create!
      credit_card = Braintree::CreditCard.create!(
        :cardholder_name => "Original Holder",
        :customer_id => customer.id,
        :cvv => "123",
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2012",
        :billing_address => {
          :first_name => "Old First Name",
          :last_name => "Old Last Name",
          :company => "Old Company",
          :street_address => "123 Old St",
          :extended_address => "Apt Old",
          :locality => "Old City",
          :region => "Old State",
          :postal_code => "12345",
          :country_name => "Canada"
        },
      )
      result = Braintree::CreditCard.update(credit_card.token,
        :options => {:verify_card => false},
        :billing_address => {
          :first_name => "New First Name",
          :last_name => "New Last Name",
          :company => "New Company",
          :street_address => "123 New St",
          :extended_address => "Apt New",
          :locality => "New City",
          :region => "New State",
          :postal_code => "56789",
          :country_name => "United States of America"
        },
      )
      expect(result.success?).to eq(true)
      address = result.credit_card.billing_address
      expect(address.first_name).to eq("New First Name")
      expect(address.last_name).to eq("New Last Name")
      expect(address.company).to eq("New Company")
      expect(address.street_address).to eq("123 New St")
      expect(address.extended_address).to eq("Apt New")
      expect(address.locality).to eq("New City")
      expect(address.region).to eq("New State")
      expect(address.postal_code).to eq("56789")
      expect(address.country_name).to eq("United States of America")
    end

    it "returns an error response if invalid" do
      customer = Braintree::Customer.create!
      credit_card = Braintree::CreditCard.create!(
        :cardholder_name => "Original Holder",
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2012",
      )
      update_result = Braintree::CreditCard.update(credit_card.token,
        :cardholder_name => "New Holder",
        :number => "invalid",
        :expiration_date => "05/2014",
      )
      expect(update_result.success?).to eq(false)
      expect(update_result.errors.for(:credit_card).on(:number)[0].message).to eq("Credit card number must be 12-19 digits.")
    end

    it "can update the default" do
      customer = Braintree::Customer.create!
      card1 = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2009",
      ).credit_card
      card2 = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2009",
      ).credit_card

      expect(card1).to be_default
      expect(card2).not_to be_default

      Braintree::CreditCard.update(card2.token, :options => {:make_default => true})

      expect(Braintree::CreditCard.find(card1.token)).not_to be_default
      expect(Braintree::CreditCard.find(card2.token)).to be_default
    end

    context "verification_account_type" do
      it "updates the credit card with account_type credit" do
        customer = Braintree::Customer.create!
        card = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Hiper,
          :expiration_date => "06/2013",
        ).credit_card
        update_result = Braintree::CreditCard.update(
          card.token,
          :options => {
            :verify_card => true,
            :verification_account_type => "credit",
            :verification_merchant_account_id => SpecHelper::HiperBRLMerchantAccountId,
          },
        )
        expect(update_result).to be_success
      end

      it "updates the credit card with account_type debit" do
        customer = Braintree::Customer.create!
        card = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Hiper,
          :expiration_date => "06/2013",
        ).credit_card
        update_result = Braintree::CreditCard.update(
          card.token,
          :options => {
            :verify_card => true,
            :verification_account_type => "debit",
            :verification_merchant_account_id => SpecHelper::CardProcessorBRLMerchantAccountId,
          },
        )
        expect(update_result).to be_success
      end
    end
  end

  describe "self.update!" do
    it "updates the credit card and returns true if valid" do
      customer = Braintree::Customer.create!
      credit_card = Braintree::CreditCard.create!(
        :cardholder_name => "Original Holder",
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2012",
      )
      updated_credit_card = Braintree::CreditCard.update!(credit_card.token,
        :cardholder_name => "New Holder",
        :number => Braintree::Test::CreditCardNumbers::MasterCard,
        :expiration_date => "06/2013",
      )
      expect(updated_credit_card.token).to eq(credit_card.token)
      expect(updated_credit_card.bin).to eq(Braintree::Test::CreditCardNumbers::MasterCard[0, 6])
      expect(updated_credit_card.last_4).to eq(Braintree::Test::CreditCardNumbers::MasterCard[-4..-1])
      expect(updated_credit_card.expiration_date).to eq("06/2013")
      expect(updated_credit_card.cardholder_name).to eq("New Holder")
      expect(updated_credit_card.updated_at.between?(Time.now - 60, Time.now)).to eq(true)
    end

    it "raises a ValidationsFailed if invalid" do
      customer = Braintree::Customer.create!
      credit_card = Braintree::CreditCard.create!(
        :cardholder_name => "Original Holder",
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2012",
      )
      expect do
        Braintree::CreditCard.update!(credit_card.token,
          :cardholder_name => "New Holder",
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "invalid/date",
        )
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.delete" do
    it "deletes the credit card" do
      customer = Braintree::Customer.create.customer
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2012",
      )

      expect(result.success?).to eq(true)
      credit_card = result.credit_card
      expect(Braintree::CreditCard.delete(credit_card.token)).to eq(true)
      expect do
        Braintree::CreditCard.find(credit_card.token)
      end.to raise_error(Braintree::NotFoundError)
    end
  end

  describe "self.expired" do
    it "can iterate over all items, and make sure they are all expired" do
      customer = Braintree::Customer.all.first

      (110 - Braintree::CreditCard.expired.maximum_size).times do
        Braintree::CreditCard.create!(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "01/#{Time.now.year - 3}",
        )
      end

      collection = Braintree::CreditCard.expired
      expect(collection.maximum_size).to be > 100

      credit_card_ids = collection.map do |c|
        expect(c.expired?).to eq(true)
        c.token
      end.uniq.compact
      expect(credit_card_ids.size).to eq(collection.maximum_size)
    end
  end

  describe "self.expiring_between" do
    it "finds payment methods expiring between the given dates" do
      next_year = Time.now.year + 1
      collection = Braintree::CreditCard.expiring_between(Time.mktime(next_year, 1), Time.mktime(next_year, 12))
      expect(collection.maximum_size).to be > 0
      collection.all? { |pm| expect(pm.expired?).to eq(false) }
      collection.all? { |pm| expect(pm.expiration_year).to eq(next_year.to_s) }
    end

    it "can iterate over all items" do
      customer = Braintree::Customer.all.first

      (110 - Braintree::CreditCard.expiring_between(Time.mktime(2010, 1, 1), Time.mktime(2010,3, 1)).maximum_size).times do
        Braintree::CreditCard.create!(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "01/2010",
        )
      end

      collection = Braintree::CreditCard.expiring_between(Time.mktime(2010, 1, 1), Time.mktime(2010,3, 1))
      expect(collection.maximum_size).to be > 100

      credit_card_ids = collection.map { |c| c.token }.uniq.compact
      expect(credit_card_ids.size).to eq(collection.maximum_size)
    end
  end

  describe "self.find" do
    it "finds the payment method with the given token" do
      customer = Braintree::Customer.create.customer
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2012",
      )
      expect(result.success?).to eq(true)
      credit_card = Braintree::CreditCard.find(result.credit_card.token)
      expect(credit_card.bin).to eq(Braintree::Test::CreditCardNumbers::Visa[0, 6])
      expect(credit_card.last_4).to eq(Braintree::Test::CreditCardNumbers::Visa[-4..-1])
      expect(credit_card.token).to eq(result.credit_card.token)
      expect(credit_card.expiration_date).to eq("05/2012")
    end

    it "returns associated subscriptions with the credit card" do
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

      found_card = Braintree::CreditCard.find(credit_card.token)
      expect(found_card.subscriptions.first.id).to eq(subscription.id)
      expect(found_card.subscriptions.first.plan_id).to eq("integration_trialless_plan")
      expect(found_card.subscriptions.first.payment_method_token).to eq(credit_card.token)
      expect(found_card.subscriptions.first.price).to eq(BigDecimal("1.00"))
    end

    it "raises a NotFoundError exception if payment method cannot be found" do
      expect do
        Braintree::CreditCard.find("invalid-token")
      end.to raise_error(Braintree::NotFoundError, 'payment method with token "invalid-token" not found')
    end

    it "raises a NotFoundError exception if searching for a PayPalAccount token" do
      customer = Braintree::Customer.create!
      paypal_account_token = "PAYPAL_ACCOUNT_TOKEN_#{rand(36**3).to_s(36)}"
      paypal_nonce = nonce_for_paypal_account({
          :consent_code => "PAYPAL_CONSENT_CODE",
          :token => paypal_account_token
      })

      Braintree::PaymentMethod.create({
        :payment_method_nonce => paypal_nonce,
        :customer_id => customer.id
      })

      expect do
        Braintree::CreditCard.find(paypal_account_token)
      end.to raise_error(Braintree::NotFoundError, "payment method with token \"#{paypal_account_token}\" not found")
    end
  end

  describe "self.from_nonce" do
    it "finds the payment method with the given nonce" do
      customer = Braintree::Customer.create!
      nonce = nonce_for_new_payment_method(
        :credit_card => {
          :number => "4111111111111111",
          :expiration_month => "11",
          :expiration_year => "2099",
        },
        :client_token_options => {:customer_id => customer.id},
      )

      credit_card = Braintree::CreditCard.from_nonce(nonce)
      customer = Braintree::Customer.find(customer.id)
      expect(credit_card).to eq(customer.credit_cards.first)
    end

    it "does not find a payment method for an unlocked nonce that points to a shared credit card" do
      nonce = nonce_for_new_payment_method(
        :credit_card => {
          :number => "4111111111111111",
          :expiration_month => "11",
          :expiration_year => "2099",
        },
      )
      expect do
        Braintree::CreditCard.from_nonce(nonce)
      end.to raise_error(Braintree::NotFoundError)
    end

    it "does not find the payment method for a consumednonce" do
      customer = Braintree::Customer.create!
      nonce = nonce_for_new_payment_method(
        :credit_card => {
          :number => "4111111111111111",
          :expiration_month => "11",
          :expiration_year => "2099",
        },
        :client_token_options => {:customer_id => customer.id},
      )

      Braintree::CreditCard.from_nonce(nonce)
      expect do
        Braintree::CreditCard.from_nonce(nonce)
      end.to raise_error(Braintree::NotFoundError, /consumed/)
    end
  end

  # NEXT_MAJOR_VERSION remove these tests
  # CreditCard.sale has been deprecated in favor of Transaction.sale
  describe "self.sale" do
    it "creates a sale transaction using the credit card, returning a result object" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        },
      )
      result = Braintree::CreditCard.sale(customer.credit_cards[0].token, :amount => "100.00")

      expect(result.success?).to eq(true)
      expect(result.transaction.amount).to eq(BigDecimal("100.00"))
      expect(result.transaction.type).to eq("sale")
      expect(result.transaction.customer_details.id).to eq(customer.id)
      expect(result.transaction.credit_card_details.token).to eq(customer.credit_cards[0].token)
      expect(result.transaction.credit_card_details.bin).to eq(Braintree::Test::CreditCardNumbers::Visa[0, 6])
      expect(result.transaction.credit_card_details.last_4).to eq(Braintree::Test::CreditCardNumbers::Visa[-4..-1])
      expect(result.transaction.credit_card_details.expiration_date).to eq("05/2010")
    end

    it "allows passing a cvv in addition to the token" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        },
      )
      result = Braintree::CreditCard.sale(customer.credit_cards[0].token,
        :amount => "100.00",
        :credit_card => {
          :cvv => "301"
        },
      )

      expect(result.success?).to eq(true)
      expect(result.transaction.amount).to eq(BigDecimal("100.00"))
      expect(result.transaction.type).to eq("sale")
      expect(result.transaction.customer_details.id).to eq(customer.id)
      expect(result.transaction.credit_card_details.token).to eq(customer.credit_cards[0].token)
      expect(result.transaction.cvv_response_code).to eq("S")
    end
  end

  # NEXT_MAJOR_VERSION remove this test
  # CreditCard.sale has been deprecated in favor of Transaction.sale
  describe "self.sale!" do
    it "creates a sale transaction using the credit card, returning the transaction" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        },
      )
      transaction = Braintree::CreditCard.sale!(customer.credit_cards[0].token, :amount => "100.00")
      expect(transaction.amount).to eq(BigDecimal("100.00"))
      expect(transaction.type).to eq("sale")
      expect(transaction.customer_details.id).to eq(customer.id)
      expect(transaction.credit_card_details.token).to eq(customer.credit_cards[0].token)
      expect(transaction.credit_card_details.bin).to eq(Braintree::Test::CreditCardNumbers::Visa[0, 6])
      expect(transaction.credit_card_details.last_4).to eq(Braintree::Test::CreditCardNumbers::Visa[-4..-1])
      expect(transaction.credit_card_details.expiration_date).to eq("05/2010")
    end
  end

  describe "nonce" do
    it "returns the credit card nonce" do
      customer = Braintree::Customer.create!
      credit_card = Braintree::CreditCard.create!(
        :cardholder_name => "Original Holder",
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2012",
      )

      expect(credit_card.nonce).not_to be_nil
    end
  end

  describe "card on file network tokenization" do
    it "should find a network tokenized credit card" do
      credit_card = Braintree::CreditCard.find("network_tokenized_credit_card")
      expect(credit_card.is_network_tokenized?).to eq(true)
    end

    it "should find a non-network tokenized credit card" do
      customer = Braintree::Customer.create!
      credit_card = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2009",
      ).credit_card
      credit_card_vaulted = Braintree::CreditCard.find(credit_card.token)
      expect(credit_card_vaulted.is_network_tokenized?).to eq(false)
    end
  end
end
