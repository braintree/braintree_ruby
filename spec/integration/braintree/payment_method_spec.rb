require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

def make_token
 SecureRandom.uuid
end

describe Braintree::PaymentMethod do
  describe "self.create" do
    it "creates a payment method from a vaulted credit card nonce" do
      config = Braintree::Configuration.instantiate
      customer = Braintree::Customer.create.customer
      raw_client_token = Braintree::ClientToken.generate(:customer_id => customer.id)
      client_token = decode_client_token(raw_client_token)
      authorization_fingerprint = client_token["authorizationFingerprint"]
      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => authorization_fingerprint,
        :shared_customer_identifier => "fake_identifier",
        :shared_customer_identifier_type => "testing",
      )

      response = http.create_credit_card(
        :number => 4111111111111111,
        :expirationMonth => 12,
        :expirationYear => 2020,
      )
      expect(response.code).to eq("201")

      nonce = JSON.parse(response.body)["creditCards"].first["nonce"]
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
      )

      expect(result).to be_success
      expect(result.payment_method).to be_a(Braintree::CreditCard)
      token = result.payment_method.token

      found_credit_card = Braintree::CreditCard.find(token)
      expect(found_credit_card).not_to be_nil
    end

    it "creates a payment method from an unvalidated credit card nonce" do
      config = Braintree::Configuration.instantiate
      customer = Braintree::Customer.create.customer
      raw_client_token = Braintree::ClientToken.generate(:customer_id => customer.id)
      client_token = decode_client_token(raw_client_token)
      authorization_fingerprint = client_token["authorizationFingerprint"]
      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => authorization_fingerprint,
        :shared_customer_identifier => "fake_identifier",
        :shared_customer_identifier_type => "testing",
      )

      response = http.create_credit_card(
        :number => "4111111111111111",
        :expirationMonth => "12",
        :expirationYear => "2020",
        :options => {:validate => false},
      )
      expect(response.code).to eq("202")

      nonce = JSON.parse(response.body)["creditCards"].first["nonce"]
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
      )

      expect(result).to be_success
      expect(result.payment_method).to be_a(Braintree::CreditCard)
      token = result.payment_method.token

      found_credit_card = Braintree::CreditCard.find(token)
      expect(found_credit_card).not_to be_nil
    end

    it "creates a payment method from a fake apple pay nonce" do
      customer = Braintree::Customer.create.customer
      token = SecureRandom.hex(16)
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => Braintree::Test::Nonce::ApplePayAmEx,
        :customer_id => customer.id,
        :token => token,
      )

      expect(result).to be_success
      apple_pay_card = result.payment_method
      expect(apple_pay_card).to be_a(Braintree::ApplePayCard)
      expect(apple_pay_card).not_to be_nil
      expect(apple_pay_card.bin).not_to be_nil
      expect(apple_pay_card.token).to eq(token)
      expect(apple_pay_card.card_type).to eq(Braintree::ApplePayCard::CardType::AmEx)
      expect(apple_pay_card.payment_instrument_name).to eq("AmEx 41002")
      expect(apple_pay_card.source_description).to eq("AmEx 41002")
      expect(apple_pay_card.default).to eq(true)
      expect(apple_pay_card.image_url).to match(/apple_pay/)
      expect(apple_pay_card.expiration_month.to_i).to be > 0
      expect(apple_pay_card.expiration_year.to_i).to be > 0
      expect(apple_pay_card.customer_id).to eq(customer.id)
      expect(apple_pay_card.commercial).not_to be_nil
      expect(apple_pay_card.country_of_issuance).not_to be_nil
      expect(apple_pay_card.debit).not_to be_nil
      expect(apple_pay_card.durbin_regulated).not_to be_nil
      expect(apple_pay_card.healthcare).not_to be_nil
      expect(apple_pay_card.issuing_bank).not_to be_nil
      expect(apple_pay_card.payroll).not_to be_nil
      expect(apple_pay_card.prepaid).not_to be_nil
      expect(apple_pay_card.product_id).not_to be_nil
      expect(apple_pay_card.is_device_token).to eq(true)
    end

    it "creates a payment method from a fake apple pay mpan nonce" do
      customer = Braintree::Customer.create.customer
      token = SecureRandom.hex(16)
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => Braintree::Test::Nonce::ApplePayMpan,
        :customer_id => customer.id,
        :token => token,
      )

      expect(result).to be_success
      apple_pay_card = result.payment_method
      expect(apple_pay_card).to be_a(Braintree::ApplePayCard)
      expect(apple_pay_card).not_to be_nil
      expect(apple_pay_card.bin).not_to be_nil
      expect(apple_pay_card.token).to eq(token)
      expect(apple_pay_card.card_type).to eq(Braintree::ApplePayCard::CardType::Visa)
      expect(apple_pay_card.payment_instrument_name).to eq("Visa 2006")
      expect(apple_pay_card.source_description).to eq("Visa 2006")
      expect(apple_pay_card.default).to eq(true)
      expect(apple_pay_card.image_url).to match(/apple_pay/)
      expect(apple_pay_card.expiration_month.to_i).to be > 0
      expect(apple_pay_card.expiration_year.to_i).to be > 0
      expect(apple_pay_card.customer_id).to eq(customer.id)
      expect(apple_pay_card.commercial).not_to be_nil
      expect(apple_pay_card.country_of_issuance).not_to be_nil
      expect(apple_pay_card.debit).not_to be_nil
      expect(apple_pay_card.durbin_regulated).not_to be_nil
      expect(apple_pay_card.healthcare).not_to be_nil
      expect(apple_pay_card.issuing_bank).not_to be_nil
      expect(apple_pay_card.payroll).not_to be_nil
      expect(apple_pay_card.prepaid).not_to be_nil
      expect(apple_pay_card.product_id).not_to be_nil
      expect(apple_pay_card.merchant_token_identifier).not_to be_nil
      expect(apple_pay_card.is_device_token).not_to be_nil
      expect(apple_pay_card.source_card_last4).not_to be_nil
    end

    it "creates a payment method from a fake google pay proxy card nonce" do
      customer = Braintree::Customer.create.customer
      token = SecureRandom.hex(16)
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => Braintree::Test::Nonce::GooglePayDiscover,
        :customer_id => customer.id,
        :token => token,
      )

      expect(result).to be_success
      google_pay_card = result.payment_method
      expect(google_pay_card).to be_a(Braintree::GooglePayCard)
      expect(google_pay_card).not_to be_nil
      expect(google_pay_card.token).to eq(token)
      expect(google_pay_card.card_type).to eq(Braintree::CreditCard::CardType::Discover)
      expect(google_pay_card.virtual_card_type).to eq(Braintree::CreditCard::CardType::Discover)
      expect(google_pay_card.expiration_month.to_i).to be > 0
      expect(google_pay_card.expiration_year.to_i).to be > 0
      expect(google_pay_card.default).to eq(true)
      expect(google_pay_card.image_url).to match(/android_pay/)
      expect(google_pay_card.is_network_tokenized?).to eq(false)
      expect(google_pay_card.source_card_type).to eq(Braintree::CreditCard::CardType::Discover)
      expect(google_pay_card.source_card_last_4).to eq("1111")
      expect(google_pay_card.google_transaction_id).to eq("google_transaction_id")
      expect(google_pay_card.source_description).to eq("Discover 1111")
      expect(google_pay_card.customer_id).to eq(customer.id)
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

    it "creates a payment method from a google pay network token nonce" do
      customer = Braintree::Customer.create.customer
      token = SecureRandom.hex(16)
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => Braintree::Test::Nonce::GooglePayMasterCard,
        :customer_id => customer.id,
        :token => token,
      )

      expect(result).to be_success
      google_pay_card = result.payment_method
      expect(google_pay_card).to be_a(Braintree::GooglePayCard)
      expect(google_pay_card).not_to be_nil
      expect(google_pay_card.token).to eq(token)
      expect(google_pay_card.card_type).to eq(Braintree::CreditCard::CardType::MasterCard)
      expect(google_pay_card.virtual_card_type).to eq(Braintree::CreditCard::CardType::MasterCard)
      expect(google_pay_card.expiration_month.to_i).to be > 0
      expect(google_pay_card.expiration_year.to_i).to be > 0
      expect(google_pay_card.default).to eq(true)
      expect(google_pay_card.image_url).to match(/android_pay/)
      expect(google_pay_card.is_network_tokenized?).to eq(true)
      expect(google_pay_card.source_card_type).to eq(Braintree::CreditCard::CardType::MasterCard)
      expect(google_pay_card.source_card_last_4).to eq("4444")
      expect(google_pay_card.google_transaction_id).to eq("google_transaction_id")
      expect(google_pay_card.source_description).to eq("MasterCard 4444")
      expect(google_pay_card.customer_id).to eq(customer.id)
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

    it "creates a payment method from venmo account nonce" do
      customer = Braintree::Customer.create.customer
      token = SecureRandom.hex(16)
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => Braintree::Test::Nonce::VenmoAccount,
        :customer_id => customer.id,
        :token => token,
      )

      expect(result).to be_success
      venmo_account = result.payment_method
      expect(venmo_account).to be_a(Braintree::VenmoAccount)

      expect(venmo_account.default).to eq(true)
      expect(venmo_account.token).to eq(token)
      expect(venmo_account.username).to eq("venmojoe")
      expect(venmo_account.venmo_user_id).to eq("1234567891234567891")
      expect(venmo_account.image_url).to include(".png")
      expect(venmo_account.source_description).to eq("Venmo Account: venmojoe")
      expect(venmo_account.customer_id).to eq(customer.id)
    end

    it "allows passing the make_default option alongside the nonce" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2009",
        :cvv => "100",
      )
      expect(result.success?).to eq(true)
      original_payment_method = result.credit_card
      expect(original_payment_method).to be_default

      nonce = nonce_for_paypal_account(:consent_code => "PAYPAL_CONSENT_CODE")
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :options => {:make_default => true},
      )

      expect(result).to be_success
      new_payment_method = result.payment_method
      expect(new_payment_method).to be_default
    end

    it "overrides the token in the nonce" do
      customer = Braintree::Customer.create!

      first_token = make_token
      second_token = make_token
      nonce = nonce_for_paypal_account(
        :consent_code => "PAYPAL_CONSENT_CODE",
        :token => first_token,
      )
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :token => second_token,
      )

      expect(result).to be_success
      payment_method = result.payment_method
      expect(payment_method.token).to eq(second_token)
    end

    it "respects verify_card and verification_merchant_account_id when included outside of the nonce" do
      nonce = nonce_for_new_payment_method(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::Visa,
          :expiration_month => "11",
          :expiration_year => "2099",
        },
      )
      customer = Braintree::Customer.create!
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :options => {
          :verify_card => true,
          :verification_merchant_account_id => SpecHelper::NonDefaultMerchantAccountId
        },
      )

      expect(result).not_to be_success
      expect(result.credit_card_verification.status).to eq(Braintree::Transaction::Status::ProcessorDeclined)
      expect(result.credit_card_verification.processor_response_code).to eq("2000")
      expect(result.credit_card_verification.processor_response_text).to eq("Do Not Honor")
      expect(result.credit_card_verification.merchant_account_id).to eq(SpecHelper::NonDefaultMerchantAccountId)
    end

    it "respects verification amount when included outside of the nonce" do
      nonce = nonce_for_new_payment_method(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::Visa,
          :expiration_month => "11",
          :expiration_year => "2099",
        },
      )
      customer = Braintree::Customer.create!
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :options => {
          :verify_card => true,
          :verification_amount => "100.00"
        },
      )

      expect(result).not_to be_success
      expect(result.credit_card_verification.status).to eq(Braintree::Transaction::Status::ProcessorDeclined)
      expect(result.credit_card_verification.processor_response_code).to eq("2000")
      expect(result.credit_card_verification.processor_response_text).to eq("Do Not Honor")
      expect(result.credit_card_verification.amount).to eq(BigDecimal("100.00"))
    end

    it "validates presence of three_d_secure_version in 3ds pass thru params" do
      customer = Braintree::Customer.create!
      result = Braintree::PaymentMethod.create(
        :customer_id => customer.id,
        :payment_method_nonce => Braintree::Test::Nonce::Transactable,
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
        :options => {:verify_card => true},
      )
      expect(result).not_to be_success
      error = result.errors.for(:verification).first
      expect(error.code).to eq(Braintree::ErrorCodes::Verification::ThreeDSecurePassThru::ThreeDSecureVersionIsInvalid)
      expect(error.message).to eq("The version of 3D Secure authentication must be composed only of digits and separated by periods (e.g. `1.0.2`).")
    end

    it "accepts three_d_secure pass thru params in the request" do
      customer = Braintree::Customer.create!
      result = Braintree::PaymentMethod.create(
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

      expect(result).to be_success
    end

    it "returns 3DS info on cc verification" do
      customer = Braintree::Customer.create.customer
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => Braintree::Test::Nonce::ThreeDSecureVisaFullAuthentication,
        :options => {:verify_card => true},
        :customer_id => customer.id,
      )
      expect(result.success?).to eq(true)

      three_d_secure_info = result.payment_method.verification.three_d_secure_info
      expect(three_d_secure_info.status).to eq("authenticate_successful")
      expect(three_d_secure_info).to be_liability_shifted
      expect(three_d_secure_info).to be_liability_shift_possible
      expect(three_d_secure_info.enrolled).to be_a(String)
      expect(three_d_secure_info.cavv).to be_a(String)
      expect(three_d_secure_info.xid).to be_a(String)
      expect(three_d_secure_info.eci_flag).to be_a(String)
      expect(three_d_secure_info.three_d_secure_version).to be_a(String)
    end

    it "respects fail_on_duplicate_payment_method when included outside of the nonce" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2012",
      )
      expect(result).to be_success

      nonce = nonce_for_new_payment_method(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2012"
        },
      )
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :options => {
          :fail_on_duplicate_payment_method => true
        },
      )

      expect(result).not_to be_success
      expect(result.errors.first.code).to eq("81724")
    end

    it "respects fail_on_duplicate_payment_method_for_customer when included outside of the nonce" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => 4111111111111111,
        :expiration_date => "05/2012",
      )
      expect(result).to be_success

      nonce = nonce_for_new_payment_method(
        :credit_card => {
          :number => 4111111111111111,
          :expiration_date => "05/2012"
        },
      )
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :options => {
          :fail_on_duplicate_payment_method_for_customer => true
        },
      )

      expect(result).not_to be_success
      expect(result.errors.first.code).to eq("81763")
    end

    it "allows passing the billing address outside of the nonce" do
      config = Braintree::Configuration.instantiate
      customer = Braintree::Customer.create.customer
      raw_client_token = Braintree::ClientToken.generate(:customer_id => customer.id)
      client_token = decode_client_token(raw_client_token)
      authorization_fingerprint = client_token["authorizationFingerprint"]
      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => authorization_fingerprint,
        :shared_customer_identifier => "fake_identifier",
        :shared_customer_identifier_type => "testing",
      )

      response = http.create_credit_card(
        :number => "4111111111111111",
        :expirationMonth => "12",
        :expirationYear => "2020",
        :options => {:validate => false},
      )
      expect(response.code).to eq("202")

      nonce = JSON.parse(response.body)["creditCards"].first["nonce"]
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :billing_address => {
          :street_address => "123 Abc Way",
          :international_phone => {:country_code => "1", :national_number => "3121234567"},
        },
      )

      expect(result).to be_success
      expect(result.payment_method).to be_a(Braintree::CreditCard)
      token = result.payment_method.token

      found_credit_card = Braintree::CreditCard.find(token)
      expect(found_credit_card).not_to be_nil
      expect(found_credit_card.billing_address.street_address).to eq("123 Abc Way")
      expect(found_credit_card.billing_address.international_phone[:country_code]).to eq("1")
      expect(found_credit_card.billing_address.international_phone[:national_number]).to eq("3121234567")
    end

    it "allows passing a billing address id outside of the nonce" do
      config = Braintree::Configuration.instantiate
      customer = Braintree::Customer.create.customer
      raw_client_token = Braintree::ClientToken.generate(:customer_id => customer.id)
      client_token = decode_client_token(raw_client_token)
      authorization_fingerprint = client_token["authorizationFingerprint"]
      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => authorization_fingerprint,
        :shared_customer_identifier => "fake_identifier",
        :shared_customer_identifier_type => "testing",
      )

      response = http.create_credit_card(
        :number => "4111111111111111",
        :expirationMonth => "12",
        :expirationYear => "2020",
        :options => {:validate => false},
      )
      expect(response.code).to eq("202")

      nonce = JSON.parse(response.body)["creditCards"].first["nonce"]

      address = Braintree::Address.create!(:customer_id => customer.id, :first_name => "Bobby", :last_name => "Tables")
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :billing_address_id => address.id,
      )

      expect(result).to be_success
      expect(result.payment_method).to be_a(Braintree::CreditCard)
      token = result.payment_method.token

      found_credit_card = Braintree::CreditCard.find(token)
      expect(found_credit_card).not_to be_nil
      expect(found_credit_card.billing_address.first_name).to eq("Bobby")
      expect(found_credit_card.billing_address.last_name).to eq("Tables")
    end

    it "overrides the billing address in the nonce" do
      config = Braintree::Configuration.instantiate
      customer = Braintree::Customer.create.customer
      raw_client_token = Braintree::ClientToken.generate(:customer_id => customer.id)
      client_token = decode_client_token(raw_client_token)
      authorization_fingerprint = client_token["authorizationFingerprint"]
      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => authorization_fingerprint,
        :shared_customer_identifier => "fake_identifier",
        :shared_customer_identifier_type => "testing",
      )

      response = http.create_credit_card(
        :number => "4111111111111111",
        :expirationMonth => "12",
        :expirationYear => "2020",
        :options => {:validate => false},
        :billing_address => {
          :street_address => "456 Xyz Way"
        },
      )
      expect(response.code).to eq("202")

      nonce = JSON.parse(response.body)["creditCards"].first["nonce"]
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :billing_address => {
          :street_address => "123 Abc Way"
        },
      )

      expect(result).to be_success
      expect(result.payment_method).to be_a(Braintree::CreditCard)
      token = result.payment_method.token

      found_credit_card = Braintree::CreditCard.find(token)
      expect(found_credit_card).not_to be_nil
      expect(found_credit_card.billing_address.street_address).to eq("123 Abc Way")
    end

    it "does not override the billing address for a vaulted credit card" do
      config = Braintree::Configuration.instantiate
      customer = Braintree::Customer.create.customer
      raw_client_token = Braintree::ClientToken.generate(:customer_id => customer.id)
      client_token = decode_client_token(raw_client_token)
      authorization_fingerprint = client_token["authorizationFingerprint"]
      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => authorization_fingerprint,
        :shared_customer_identifier => "fake_identifier",
        :shared_customer_identifier_type => "testing",
      )

      response = http.create_credit_card(
        :number => 4111111111111111,
        :expirationMonth => 12,
        :expirationYear => 2020,
        :billing_address => {
          :street_address => "456 Xyz Way"
        },
      )
      expect(response.code).to eq("201")

      nonce = JSON.parse(response.body)["creditCards"].first["nonce"]
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
        :billing_address => {
          :street_address => "123 Abc Way"
        },
      )

      expect(result).to be_success
      expect(result.payment_method).to be_a(Braintree::CreditCard)
      token = result.payment_method.token

      found_credit_card = Braintree::CreditCard.find(token)
      expect(found_credit_card).not_to be_nil
      expect(found_credit_card.billing_address.street_address).to eq("456 Xyz Way")
    end

    it "includes risk data when skip_advanced_fraud_checking is false" do
      with_fraud_protection_enterprise_merchant do
        customer = Braintree::Customer.create!

        nonce = nonce_for_new_payment_method(
          :credit_card => {
            :cvv => "123",
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009",
          },
        )
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
          :options => {
            :verify_card => true,
            :skip_advanced_fraud_checking => false,
          },
        )

        expect(result).to be_success
        verification = result.payment_method.verification
        expect(verification.risk_data).not_to be_nil
      end
    end

    it "does not include risk data when skip_advanced_fraud_checking is true" do
      with_fraud_protection_enterprise_merchant do
        customer = Braintree::Customer.create!

        nonce = nonce_for_new_payment_method(
          :credit_card => {
            :cvv => "123",
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009",
          },
        )
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
          :options => {
            :verify_card => true,
            :skip_advanced_fraud_checking => true,
          },
        )

        expect(result).to be_success
        verification = result.payment_method.verification
        expect(verification.risk_data).to be_nil
      end
    end

      it "includes ani response when account information inquiry is sent in options" do
          customer = Braintree::Customer.create!
          nonce = nonce_for_new_payment_method(
            :credit_card => {
              :cvv => "123",
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "05/2029",
            },
          )
          result = Braintree::PaymentMethod.create(
            :payment_method_nonce => nonce,
            :customer_id => customer.id,
            :options => {
              :verify_card => true,
              :account_information_inquiry => "send_data",
            },
          )

          expect(result).to be_success
          verification = result.payment_method.verification
          expect(verification.ani_first_name_response_code).not_to be_nil
          expect(verification.ani_last_name_response_code).not_to be_nil
      end

    context "account_type" do
      it "verifies card with account_type debit" do
        nonce = nonce_for_new_payment_method(
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Hiper,
            :expiration_month => "11",
            :expiration_year => "2099",
          },
        )
        customer = Braintree::Customer.create!
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
          :options => {
            :verify_card => true,
            :verification_merchant_account_id => SpecHelper::CardProcessorBRLMerchantAccountId,
            :verification_account_type => "debit",
          },
        )

        expect(result).to be_success
        expect(result.payment_method.verification.credit_card[:account_type]).to eq("debit")
      end

      it "verifies card with account_type credit" do
        nonce = nonce_for_new_payment_method(
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Hiper,
            :expiration_month => "11",
            :expiration_year => "2099",
          },
        )
        customer = Braintree::Customer.create!
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
          :options => {
            :verify_card => true,
            :verification_merchant_account_id => SpecHelper::HiperBRLMerchantAccountId,
            :verification_account_type => "credit",
          },
        )

        expect(result).to be_success
        expect(result.payment_method.verification.credit_card[:account_type]).to eq("credit")
      end

      it "errors with invalid account_type" do
        nonce = nonce_for_new_payment_method(
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Hiper,
            :expiration_month => "11",
            :expiration_year => "2099",
          },
        )
        customer = Braintree::Customer.create!
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
          :options => {
            :verify_card => true,
            :verification_merchant_account_id => SpecHelper::HiperBRLMerchantAccountId,
            :verification_account_type => "ach",
          },
        )

        expect(result).not_to be_success
        expect(result.errors.for(:credit_card).for(:options).on(:verification_account_type)[0].code).to eq(Braintree::ErrorCodes::CreditCard::VerificationAccountTypeIsInvalid)
      end

      it "errors when account_type not supported by merchant" do
        nonce = nonce_for_new_payment_method(
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_month => "11",
            :expiration_year => "2099",
          },
        )
        customer = Braintree::Customer.create!
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
          :options => {
            :verify_card => true,
            :verification_account_type => "credit",
          },
        )

        expect(result).not_to be_success
        expect(result.errors.for(:credit_card).for(:options).on(:verification_account_type)[0].code).to eq(Braintree::ErrorCodes::CreditCard::VerificationAccountTypeNotSupported)
      end

      it "updates the credit card with account_type credit" do
        customer = Braintree::Customer.create!
        credit_card = Braintree::CreditCard.create!(
          :cardholder_name => "Original Holder",
          :customer_id => customer.id,
          :cvv => "123",
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2012",
        )
        update_result = Braintree::PaymentMethod.update(credit_card.token,
          :cardholder_name => "New Holder",
          :cvv => "456",
          :number => Braintree::Test::CreditCardNumbers::Hiper,
          :expiration_date => "06/2013",
          :options => {
            :verify_card => true,
            :verification_merchant_account_id => SpecHelper::HiperBRLMerchantAccountId,
            :verification_account_type => "credit",
          },
        )
        expect(update_result.success?).to eq(true)
        expect(update_result.payment_method.verification.credit_card[:account_type]).to eq("credit")
      end

      it "updates the credit card with account_type debit" do
        customer = Braintree::Customer.create!
        credit_card = Braintree::CreditCard.create!(
          :cardholder_name => "Original Holder",
          :customer_id => customer.id,
          :cvv => "123",
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2012",
        )
        update_result = Braintree::PaymentMethod.update(credit_card.token,
          :cardholder_name => "New Holder",
          :cvv => "456",
          :number => Braintree::Test::CreditCardNumbers::Hiper,
          :expiration_date => "06/2013",
          :options => {
            :verify_card => true,
            :verification_merchant_account_id => SpecHelper::CardProcessorBRLMerchantAccountId,
            :verification_account_type => "debit",
          },
        )
        expect(update_result.success?).to eq(true)
        expect(update_result.payment_method.verification.credit_card[:account_type]).to eq("debit")
      end
    end

    context "paypal" do
      it "creates a payment method from an unvalidated future paypal account nonce" do
        nonce = nonce_for_paypal_account(:consent_code => "PAYPAL_CONSENT_CODE")
        customer = Braintree::Customer.create.customer
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
        )

        expect(result).to be_success
        expect(result.payment_method).to be_a(Braintree::PayPalAccount)
        expect(result.payment_method.image_url).not_to be_nil
        token = result.payment_method.token

        found_paypal_account = Braintree::PayPalAccount.find(token)
        expect(found_paypal_account).not_to be_nil
      end

      it "creates a limited use payment method from a paypal account nonce for a paypal intent==order payment" do
        nonce = nonce_for_paypal_account(
          :intent => "order",
          :payment_token => "fake-payment-token",
          :payer_id => "fake-payer-id",
        )
        customer = Braintree::Customer.create.customer
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
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
        expect(result.payment_method).to be_a(Braintree::PayPalAccount)
        expect(result.payment_method.image_url).not_to be_nil
        expect(result.payment_method.payer_id).not_to be_nil
        token = result.payment_method.token

        found_paypal_account = Braintree::PayPalAccount.find(token)
        expect(found_paypal_account).not_to be_nil
        expect(found_paypal_account.payer_id).not_to be_nil
      end

      it "creates a billing agreement payment method from a refresh token" do
        customer = Braintree::Customer.create.customer
        result = Braintree::PaymentMethod.create(
          :customer_id => customer.id,
          :paypal_refresh_token => "some_future_payment_token",
        )

        expect(result).to be_success
        expect(result.payment_method).to be_a(Braintree::PayPalAccount)
        expect(result.payment_method.billing_agreement_id).to eq("B_FAKE_ID")
        expect(result.payment_method.payer_id).not_to be_nil
        token = result.payment_method.token

        found_paypal_account = Braintree::PayPalAccount.find(token)
        expect(found_paypal_account).not_to be_nil
        expect(found_paypal_account.billing_agreement_id).to eq("B_FAKE_ID")
        expect(found_paypal_account.payer_id).not_to be_nil
      end

      it "does not create a payment method from an unvalidated onetime paypal account nonce" do
        customer = Braintree::Customer.create.customer
        nonce = nonce_for_paypal_account(:access_token => "PAYPAL_ACCESS_TOKEN")
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
        )

        expect(result).not_to be_success
        expect(result.errors.first.code).to eq("82902")
      end

      it "ignores passed billing address params" do
        nonce = nonce_for_paypal_account(:consent_code => "PAYPAL_CONSENT_CODE")
        customer = Braintree::Customer.create.customer
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
          :billing_address => {
            :street_address => "123 Abc Way"
          },
        )

        expect(result).to be_success
        expect(result.payment_method).to be_a(Braintree::PayPalAccount)
        expect(result.payment_method.image_url).not_to be_nil
        token = result.payment_method.token

        found_paypal_account = Braintree::PayPalAccount.find(token)
        expect(found_paypal_account).not_to be_nil
      end

      it "ignores passed billing address id" do
        nonce = nonce_for_paypal_account(:consent_code => "PAYPAL_CONSENT_CODE")
        customer = Braintree::Customer.create.customer
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
          :billing_address_id => "address_id",
        )

        expect(result).to be_success
        expect(result.payment_method).to be_a(Braintree::PayPalAccount)
        expect(result.payment_method.image_url).not_to be_nil
        token = result.payment_method.token

        found_paypal_account = Braintree::PayPalAccount.find(token)
        expect(found_paypal_account).not_to be_nil
      end

      it "returns appropriate validation errors" do
        customer = Braintree::Customer.create.customer
        nonce = nonce_for_paypal_account(:token => "PAYPAL_TOKEN")
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
        )

        expect(result).not_to be_success
        errors = result.errors.map(&:code)
        expect(errors).to include("82901")
        expect(errors).to include("82902")
      end

      it "doesn't return an error if credit card options are present for a paypal nonce" do
        customer = Braintree::Customer.create!
        original_token = random_payment_method_token
        nonce = nonce_for_paypal_account(
          :consent_code => "consent-code",
          :token => original_token,
        )

        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
          :options => {
            :verify_card => true,
            :fail_on_duplicate_payment_method => true,
            :verification_merchant_account_id => "not_a_real_merchant_account_id"
          },
        )

        expect(result).to be_success
      end
    end

    context "Unknown payment methods" do
      it "creates an unknown payment method from a nonce" do
        customer = Braintree::Customer.create.customer
        token = SecureRandom.hex(16)
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => Braintree::Test::Nonce::AbstractTransactable,
          :customer_id => customer.id,
          :token => token,
        )

        expect(result).to be_success
        payment_method = result.payment_method
        expect(payment_method).not_to be_nil
        expect(payment_method.token).to eq(token)
        expect(payment_method).to be_a Braintree::UnknownPaymentMethod
      end
    end

    context "verification_currency_iso_code" do
      it "validates verification_currency_iso_code against currency configured in default merchant account" do
        nonce = nonce_for_new_payment_method(
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_month => "11",
            :expiration_year => "2099",
          },
        )
        customer = Braintree::Customer.create!
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
          :options => {
            :verify_card => true,
            :verification_currency_iso_code => "USD"
          },
        )

        expect(result).to be_success
        result.payment_method.verification.currency_iso_code  == "USD"
      end

      it "validates verification_currency_iso_code against currency configured in verification_merchant_account_id" do
        nonce = nonce_for_new_payment_method(
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_month => "11",
            :expiration_year => "2099",
          },
        )
        customer = Braintree::Customer.create!
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
          :options => {
            :verify_card => true,
            :verification_merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,
            :verification_currency_iso_code => "USD"
          },
        )

        expect(result).to be_success
        result.payment_method.verification.currency_iso_code  == "USD"
        result.payment_method.verification.merchant_account_id == SpecHelper::NonDefaultMerchantAccountId
      end


      it "errors with invalid presentment currency due to verification_currency_iso_code not matching with currency configured in default merchant account" do
        nonce = nonce_for_new_payment_method(
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_month => "11",
            :expiration_year => "2099",
          },
        )
        customer = Braintree::Customer.create!
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
          :options => {
            :verify_card => true,
            :verification_currency_iso_code => "GBP"
          },
        )
        expect(result).not_to be_success
        expect(result.errors.for(:credit_card).for(:options).on(:verification_currency_iso_code)[0].code).to eq(Braintree::ErrorCodes::CreditCard::CurrencyCodeNotSupportedByMerchantAccount)
      end

      it "errors with invalid presentment currency due to verification_currency_iso_code not matching with currency configured in verification_merchant_account_id" do
        nonce = nonce_for_new_payment_method(
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_month => "11",
            :expiration_year => "2099",
          },
        )
        customer = Braintree::Customer.create!
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
          :options => {
            :verify_card => true,
            :verification_merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,
            :verification_currency_iso_code => "GBP"
          },
        )

        expect(result).not_to be_success
        expect(result.errors.for(:credit_card).for(:options).on(:verification_currency_iso_code)[0].code).to eq(Braintree::ErrorCodes::CreditCard::CurrencyCodeNotSupportedByMerchantAccount)
      end
    end
  end

  describe "self.create!" do
    it "creates a payment method from a vaulted credit card nonce" do
      config = Braintree::Configuration.instantiate
      customer = Braintree::Customer.create.customer
      raw_client_token = Braintree::ClientToken.generate(:customer_id => customer.id)
      client_token = decode_client_token(raw_client_token)
      authorization_fingerprint = client_token["authorizationFingerprint"]
      http = ClientApiHttp.new(
        config,
        :authorization_fingerprint => authorization_fingerprint,
        :shared_customer_identifier => "fake_identifier",
        :shared_customer_identifier_type => "testing",
      )

      response = http.create_credit_card(
        :number => 4111111111111111,
        :expirationMonth => 12,
        :expirationYear => 2020,
      )
      expect(response.code).to eq("201")

      nonce = JSON.parse(response.body)["creditCards"].first["nonce"]
      payment_method = Braintree::PaymentMethod.create!(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
      )

      expect(payment_method).to be_a(Braintree::CreditCard)
      token = payment_method.token

      found_credit_card = Braintree::CreditCard.find(token)
      expect(found_credit_card).not_to be_nil
    end
  end

  describe "self.find" do
    context "credit cards" do
      it "finds the payment method with the given token" do
        customer = Braintree::Customer.create.customer
        result = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2012",
        )
        expect(result.success?).to eq(true)

        credit_card = Braintree::PaymentMethod.find(result.credit_card.token)
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

        found_card = Braintree::PaymentMethod.find(credit_card.token)
        expect(found_card.subscriptions.first.id).to eq(subscription.id)
        expect(found_card.subscriptions.first.plan_id).to eq("integration_trialless_plan")
        expect(found_card.subscriptions.first.payment_method_token).to eq(credit_card.token)
        expect(found_card.subscriptions.first.price).to eq(BigDecimal("1.00"))
      end
    end

    context "paypal accounts" do
      it "finds the payment method with the given token" do
        customer = Braintree::Customer.create!
        payment_method_token = make_token
        nonce = nonce_for_paypal_account(
          :consent_code => "consent-code",
          :token => payment_method_token,
        )
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
        )
        expect(result).to be_success

        paypal_account = Braintree::PaymentMethod.find(payment_method_token)
        expect(paypal_account).to be_a(Braintree::PayPalAccount)
        expect(paypal_account.token).to eq(payment_method_token)
        expect(paypal_account.email).to eq("jane.doe@example.com")
        expect(paypal_account.customer_id).to eq(customer.id)
      end
    end

    context "apple pay cards" do
      it "finds the payment method with the given token" do
        customer = Braintree::Customer.create!
        payment_method_token = make_token
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => Braintree::Test::Nonce::ApplePayAmEx,
          :customer_id => customer.id,
          :token => payment_method_token,
        )
        expect(result).to be_success

        apple_pay_card = Braintree::PaymentMethod.find(payment_method_token)
        expect(apple_pay_card).to be_a(Braintree::ApplePayCard)
        expect(apple_pay_card).not_to be_nil
        expect(apple_pay_card.token).to eq(payment_method_token)
        expect(apple_pay_card.card_type).to eq(Braintree::ApplePayCard::CardType::AmEx)
        expect(apple_pay_card.default).to eq(true)
        expect(apple_pay_card.image_url).to match(/apple_pay/)
        expect(apple_pay_card.expiration_month.to_i).to be > 0
        expect(apple_pay_card.expiration_year.to_i).to be > 0
        expect(apple_pay_card.source_description).to eq("AmEx 41002")
        expect(apple_pay_card.customer_id).to eq(customer.id)
      end

      it "finds the payment method with the given mpan token" do
        customer = Braintree::Customer.create!
        payment_method_token = make_token
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => Braintree::Test::Nonce::ApplePayMpan,
          :customer_id => customer.id,
          :token => payment_method_token,
        )
        expect(result).to be_success

        apple_pay_card = Braintree::PaymentMethod.find(payment_method_token)
        expect(apple_pay_card).to be_a(Braintree::ApplePayCard)
        expect(apple_pay_card).not_to be_nil
        expect(apple_pay_card.token).to eq(payment_method_token)
        expect(apple_pay_card.card_type).to eq(Braintree::ApplePayCard::CardType::Visa)
        expect(apple_pay_card.default).to eq(true)
        expect(apple_pay_card.image_url).to match(/apple_pay/)
        expect(apple_pay_card.expiration_month.to_i).to be > 0
        expect(apple_pay_card.expiration_year.to_i).to be > 0
        expect(apple_pay_card.source_description).to eq("Visa 2006")
        expect(apple_pay_card.customer_id).to eq(customer.id)
        expect(apple_pay_card.is_device_token).to eq(false)
        apple_pay_card.merchant_token_identifier == "DNITHE302308980427388297"
        apple_pay_card.source_card_last4 == "2006"
      end
    end

    context "venmo accounts" do
      it "finds the payment method with the given token" do
        customer = Braintree::Customer.create!
        payment_method_token = make_token
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => Braintree::Test::Nonce::VenmoAccount,
          :customer_id => customer.id,
          :token => payment_method_token,
        )
        expect(result).to be_success

        venmo_account = Braintree::PaymentMethod.find(payment_method_token)
        expect(venmo_account).to be_a(Braintree::VenmoAccount)
        expect(venmo_account).not_to be_nil
        expect(venmo_account.token).to eq(payment_method_token)
        expect(venmo_account.default).to eq(true)
        expect(venmo_account.image_url).to match(/venmo/)
        expect(venmo_account.username).to eq("venmojoe")
        expect(venmo_account.venmo_user_id).to eq("1234567891234567891")
        expect(venmo_account.source_description).to eq("Venmo Account: venmojoe")
        expect(venmo_account.customer_id).to eq(customer.id)
      end
    end

    context "google pay cards" do
      it "finds the proxy card payment method with the given token" do
        customer = Braintree::Customer.create!
        payment_method_token = make_token
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => Braintree::Test::Nonce::GooglePayDiscover,
          :customer_id => customer.id,
          :token => payment_method_token,
        )
        expect(result).to be_success

        google_pay_card = Braintree::PaymentMethod.find(payment_method_token)
        expect(google_pay_card).to be_a(Braintree::GooglePayCard)
        expect(google_pay_card).not_to be_nil
        expect(google_pay_card.token).to eq(payment_method_token)
        expect(google_pay_card.card_type).to eq(Braintree::CreditCard::CardType::Discover)
        expect(google_pay_card.virtual_card_type).to eq(Braintree::CreditCard::CardType::Discover)
        expect(google_pay_card.expiration_month.to_i).to be > 0
        expect(google_pay_card.expiration_year.to_i).to be > 0
        expect(google_pay_card.default).to eq(true)
        expect(google_pay_card.image_url).to match(/android_pay/)
        expect(google_pay_card.is_network_tokenized?).to eq(false)
        expect(google_pay_card.source_card_type).to eq(Braintree::CreditCard::CardType::Discover)
        expect(google_pay_card.source_card_last_4).to eq("1111")
        expect(google_pay_card.google_transaction_id).to eq("google_transaction_id")
        expect(google_pay_card.source_description).to eq("Discover 1111")
        expect(google_pay_card.customer_id).to eq(customer.id)
      end

      it "finds the network token payment method with the given token" do
        customer = Braintree::Customer.create!
        payment_method_token = make_token
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => Braintree::Test::Nonce::GooglePayMasterCard,
          :customer_id => customer.id,
          :token => payment_method_token,
        )
        expect(result).to be_success

        google_pay_card = Braintree::PaymentMethod.find(payment_method_token)
        expect(google_pay_card).to be_a(Braintree::GooglePayCard)
        expect(google_pay_card).not_to be_nil
        expect(google_pay_card.token).to eq(payment_method_token)
        expect(google_pay_card.card_type).to eq(Braintree::CreditCard::CardType::MasterCard)
        expect(google_pay_card.virtual_card_type).to eq(Braintree::CreditCard::CardType::MasterCard)
        expect(google_pay_card.expiration_month.to_i).to be > 0
        expect(google_pay_card.expiration_year.to_i).to be > 0
        expect(google_pay_card.default).to eq(true)
        expect(google_pay_card.image_url).to match(/android_pay/)
        expect(google_pay_card.is_network_tokenized?).to eq(true)
        expect(google_pay_card.source_card_type).to eq(Braintree::CreditCard::CardType::MasterCard)
        expect(google_pay_card.source_card_last_4).to eq("4444")
        expect(google_pay_card.google_transaction_id).to eq("google_transaction_id")
        expect(google_pay_card.source_description).to eq("MasterCard 4444")
        expect(google_pay_card.customer_id).to eq(customer.id)
      end
    end

    context "unknown payment methods" do
      it "finds the payment method with the given token" do
        customer = Braintree::Customer.create!
        payment_method_token = make_token
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => Braintree::Test::Nonce::AbstractTransactable,
          :customer_id => customer.id,
          :token => payment_method_token,
        )
        expect(result).to be_success

        payment_method = Braintree::PaymentMethod.find(payment_method_token)
        expect(payment_method).not_to be_nil
        expect(payment_method.token).to eq(payment_method_token)
        expect(payment_method.image_url).not_to be_nil
        expect(payment_method).to be_a Braintree::UnknownPaymentMethod
        expect(payment_method.customer_id).to eq(customer.id)
      end
    end

    it "raises a NotFoundError exception if payment method cannot be found" do
      expect do
        Braintree::PaymentMethod.find("invalid-token")
      end.to raise_error(Braintree::NotFoundError, 'payment method with token "invalid-token" not found')
    end
  end

  describe "self.delete" do
    it "deletes an google pay card" do
      customer = Braintree::Customer.create!

      create_result = Braintree::PaymentMethod.create(
        :payment_method_nonce => Braintree::Test::Nonce::GooglePayDiscover,
        :customer_id => customer.id,
      )

      token = create_result.payment_method.token

      google_card = Braintree::PaymentMethod.find(token)
      expect(google_card).to be_a(Braintree::GooglePayCard)

      delete_result = Braintree::PaymentMethod.delete(token)
      expect(delete_result.success?).to eq(true)

      expect do
        Braintree::PaymentMethod.find(token)
      end.to raise_error(Braintree::NotFoundError)
    end

    it "deletes an apple pay card" do
      customer = Braintree::Customer.create!

      create_result = Braintree::PaymentMethod.create(
        :payment_method_nonce => Braintree::Test::Nonce::ApplePayAmEx,
        :customer_id => customer.id,
      )
      token = create_result.payment_method.token

      apple_pay_card = Braintree::PaymentMethod.find(token)
      expect(apple_pay_card).to be_a(Braintree::ApplePayCard)

      delete_result = Braintree::PaymentMethod.delete(token)
      expect(delete_result.success?).to eq(true)

      expect do
        Braintree::PaymentMethod.find(token)
      end.to raise_error(Braintree::NotFoundError)
    end

    it "deletes a paypal account" do
      customer = Braintree::Customer.create!
      paypal_account_token = make_token

      nonce = nonce_for_paypal_account(
        :consent_code => "PAYPAL_CONSENT_CODE",
        :token => paypal_account_token,
      )
      Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
      )

      paypal_account = Braintree::PaymentMethod.find(paypal_account_token)
      expect(paypal_account).to be_a(Braintree::PayPalAccount)

      result = Braintree::PaymentMethod.delete(paypal_account_token, {:revoke_all_grants => false})
      expect(result.success?).to eq(true)

      expect do
        Braintree::PaymentMethod.find(paypal_account_token)
      end.to raise_error(Braintree::NotFoundError, "payment method with token \"#{paypal_account_token}\" not found")
    end

    it "deletes a credit card" do
      token = make_token
      customer = Braintree::Customer.create!
      nonce = nonce_for_new_payment_method({
        :credit_card => {
          :number => "4111111111111111",
          :expiration_month => "11",
          :expiration_year => "2099",
          :token => token
        },
        :client_token_options => {:customer_id => customer.id}
      })

      Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
      )

      result = Braintree::PaymentMethod.delete(token)
      expect(result.success?).to eq(true)

      expect do
        Braintree::PaymentMethod.find(token)
      end.to raise_error(Braintree::NotFoundError, "payment method with token \"#{token}\" not found")
    end

    it "raises a NotFoundError exception if payment method cannot be found" do
      token = make_token

      expect do
        Braintree::PaymentMethod.delete(token)
      end.to raise_error(Braintree::NotFoundError)
    end
  end

  describe "self.update" do
    context "credit cards" do
      it "throws validation error when passing invalid  pass thru params" do
        customer = Braintree::Customer.create!
        credit_card = Braintree::CreditCard.create!(
          :customer_id => customer.id,
          :payment_method_nonce => Braintree::Test::Nonce::ThreeDSecureVisaFullAuthentication,
          :options => {:verify_card => true},
        )

        update_result = Braintree::PaymentMethod.update(credit_card.token,
          :cardholder_name => "New Holder",
          :cvv => "456",
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "06/2013",
          :three_d_secure_pass_thru => {
            :eci_flag => "02",
            :cavv => "some_cavv",
            :xid => "some_xid",
            :three_d_secure_version => "xx",
            :authentication_response => "Y",
            :directory_response => "Y",
            :cavv_algorithm => "2",
            :ds_transaction_id => "some_ds_transaction_id",
          },
          :options => {:verify_card => true},
        )
        expect(update_result).to_not be_success
        error = update_result.errors.for(:verification).first
        expect(error.code).to eq(Braintree::ErrorCodes::Verification::ThreeDSecurePassThru::ThreeDSecureVersionIsInvalid)
        expect(error.message).to eq("The version of 3D Secure authentication must be composed only of digits and separated by periods (e.g. `1.0.2`).")
      end

      it "updates the credit card with three_d_secure pass thru params" do
        customer = Braintree::Customer.create!
        credit_card = Braintree::CreditCard.create!(
          :customer_id => customer.id,
          :payment_method_nonce => Braintree::Test::Nonce::ThreeDSecureVisaFullAuthentication,
          :options => {:verify_card => true},
        )

        update_result = Braintree::PaymentMethod.update(credit_card.token,
          :cardholder_name => "New Holder",
          :cvv => "456",
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "06/2013",
          :three_d_secure_pass_thru => {
            :eci_flag => "02",
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
        expect(update_result.success?).to eq(true)
        expect(update_result.payment_method).to eq(credit_card)
        updated_credit_card = update_result.payment_method
        expect(updated_credit_card.cardholder_name).to eq("New Holder")
        expect(updated_credit_card.bin).to eq(Braintree::Test::CreditCardNumbers::MasterCard[0, 6])
        expect(updated_credit_card.last_4).to eq(Braintree::Test::CreditCardNumbers::MasterCard[-4..-1])
        expect(updated_credit_card.expiration_date).to eq("06/2013")
      end

      it "updates the credit card" do
        customer = Braintree::Customer.create!
        credit_card = Braintree::CreditCard.create!(
          :cardholder_name => "Original Holder",
          :customer_id => customer.id,
          :cvv => "123",
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2012",
        )
        update_result = Braintree::PaymentMethod.update(credit_card.token,
          :cardholder_name => "New Holder",
          :cvv => "456",
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "06/2013",
        )
        expect(update_result.success?).to eq(true)
        expect(update_result.payment_method).to eq(credit_card)
        updated_credit_card = update_result.payment_method
        expect(updated_credit_card.cardholder_name).to eq("New Holder")
        expect(updated_credit_card.bin).to eq(Braintree::Test::CreditCardNumbers::MasterCard[0, 6])
        expect(updated_credit_card.last_4).to eq(Braintree::Test::CreditCardNumbers::MasterCard[-4..-1])
        expect(updated_credit_card.expiration_date).to eq("06/2013")
      end

      it "includes risk data when skip_advanced_fraud_checking is false" do
        with_fraud_protection_enterprise_merchant do
          customer = Braintree::Customer.create!
          credit_card = Braintree::CreditCard.create!(
            :customer_id => customer.id,
            :cvv => "123",
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2012",
          )
          update_result = Braintree::PaymentMethod.update(
            credit_card.token,
            :cvv => "456",
            :number => Braintree::Test::CreditCardNumbers::MasterCard,
            :expiration_date => "06/2013",
            :options => {
              :verify_card => true,
              :skip_advanced_fraud_checking => false
            },
          )

          expect(update_result).to be_success
          verification = update_result.payment_method.verification
          expect(verification.risk_data).not_to be_nil
        end
      end

      it "does not include risk data when skip_advanced_fraud_checking is true" do
        with_fraud_protection_enterprise_merchant do
          customer = Braintree::Customer.create!
          credit_card = Braintree::CreditCard.create!(
            :customer_id => customer.id,
            :cvv => "123",
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2012",
          )
          update_result = Braintree::PaymentMethod.update(
            credit_card.token,
            :cvv => "456",
            :number => Braintree::Test::CreditCardNumbers::MasterCard,
            :expiration_date => "06/2013",
            :options => {
              :verify_card => true,
              :skip_advanced_fraud_checking => true
            },
          )

          expect(update_result).to be_success
          verification = update_result.payment_method.verification
          expect(verification.risk_data).to be_nil
        end
      end

      it "includes ani response after updating the options with account information inquiry" do
        customer = Braintree::Customer.create!
        credit_card = Braintree::CreditCard.create!(
          :customer_id => customer.id,
          :cvv => "123",
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2032",
        )
        update_result = Braintree::PaymentMethod.update(
          credit_card.token,
          :options => {
            :verify_card => true,
            :account_information_inquiry => "send_data",
          },
        )

        expect(update_result).to be_success
        verification = update_result.payment_method.verification
        expect(verification.ani_first_name_response_code).not_to be_nil
        expect(verification.ani_last_name_response_code).not_to be_nil
      end


      context "verification_currency_iso_code" do
        it "validates verification_currency_iso_code and updates the credit card " do
          customer = Braintree::Customer.create!
          credit_card = Braintree::CreditCard.create!(
            :cardholder_name => "Original Holder",
            :customer_id => customer.id,
            :cvv => "123",
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2012",
          )
          update_result = Braintree::PaymentMethod.update(credit_card.token,
                                                          :cardholder_name => "New Holder",
                                                          :cvv => "456",
                                                          :number => Braintree::Test::CreditCardNumbers::MasterCard,
                                                          :expiration_date => "06/2013",
                                                          :options => {:verify_card => true, :verification_currency_iso_code => "USD"},
                                                         )
          expect(update_result.success?).to eq(true)
          update_result.payment_method.verification.currency_iso_code  == "USD"
        end

        it "validates verification_currency_iso_code against the given verification_merchant_account_id and updates the credit card " do
          customer = Braintree::Customer.create!
          credit_card = Braintree::CreditCard.create!(
            :cardholder_name => "Original Holder",
            :customer_id => customer.id,
            :cvv => "123",
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2012",
          )
          update_result = Braintree::PaymentMethod.update(credit_card.token,
                                                          :cardholder_name => "New Holder",
                                                          :cvv => "456",
                                                          :number => Braintree::Test::CreditCardNumbers::MasterCard,
                                                          :expiration_date => "06/2013",
                                                          :options => {:verify_card => true, :verification_merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,  :verification_currency_iso_code => "USD"},
                                                         )
          expect(update_result.success?).to eq(true)
          update_result.payment_method.verification.currency_iso_code  == "USD"
          update_result.payment_method.verification.merchant_account_id == SpecHelper::NonDefaultMerchantAccountId
        end

        it "throws validation error when passing invalid verification_currency_iso_code" do
          customer = Braintree::Customer.create!
          credit_card = Braintree::CreditCard.create!(
            :cardholder_name => "Original Holder",
            :customer_id => customer.id,
            :cvv => "123",
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2012",
          )
          update_result = Braintree::PaymentMethod.update(credit_card.token,
                                                          :cardholder_name => "New Holder",
                                                          :cvv => "456",
                                                          :number => Braintree::Test::CreditCardNumbers::MasterCard,
                                                          :expiration_date => "06/2013",
                                                          :options => {:verify_card => true, :verification_currency_iso_code => "GBP"},
                                                         )
          expect(update_result).to_not be_success
          expect(update_result.errors.for(:credit_card).for(:options).on(:verification_currency_iso_code)[0].code).to eq(Braintree::ErrorCodes::CreditCard::CurrencyCodeNotSupportedByMerchantAccount)
        end

        it "throws validation error when passing invalid verification_currency_iso_code of the given verification merchant account id" do
          customer = Braintree::Customer.create!
          credit_card = Braintree::CreditCard.create!(
            :cardholder_name => "Original Holder",
            :customer_id => customer.id,
            :cvv => "123",
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2012",
          )
          update_result = Braintree::PaymentMethod.update(credit_card.token,
                                                          :cardholder_name => "New Holder",
                                                          :cvv => "456",
                                                          :number => Braintree::Test::CreditCardNumbers::MasterCard,
                                                          :expiration_date => "06/2013",
                                                          :options => {:verify_card => true, :verification_merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,  :verification_currency_iso_code => "GBP"},
                                                         )
          expect(update_result).to_not be_success
          expect(update_result.errors.for(:credit_card).for(:options).on(:verification_currency_iso_code)[0].code).to eq(Braintree::ErrorCodes::CreditCard::CurrencyCodeNotSupportedByMerchantAccount)
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
          update_result = Braintree::PaymentMethod.update(credit_card.token,
            :billing_address => {
              :region => "IL"
            },
          )
          expect(update_result.success?).to eq(true)
          updated_credit_card = update_result.payment_method
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
          update_result = Braintree::PaymentMethod.update(credit_card.token,
            :billing_address => {
              :international_phone => {:country_code => "1", :national_number => "3121234567"},
              :region => "IL",
              :options => {:update_existing => true}
            },
          )
          expect(update_result.success?).to eq(true)
          updated_credit_card = update_result.payment_method
          expect(updated_credit_card.billing_address.international_phone[:country_code]).to eq("1")
          expect(updated_credit_card.billing_address.international_phone[:national_number]).to eq("3121234567")
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
          update_result = Braintree::PaymentMethod.update(credit_card.token,
            :billing_address => {
              :country_name => "American Samoa",
              :country_code_alpha2 => "AS",
              :country_code_alpha3 => "ASM",
              :country_code_numeric => "016",
              :options => {:update_existing => true}
            },
          )
          expect(update_result.success?).to eq(true)
          updated_credit_card = update_result.payment_method
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
        update_result = Braintree::PaymentMethod.update(credit_card.token,
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_month => "07",
          :expiration_year => "2011",
        )
        expect(update_result.success?).to eq(true)
        expect(update_result.payment_method).to eq(credit_card)
        expect(update_result.payment_method.expiration_month).to eq("07")
        expect(update_result.payment_method.expiration_year).to eq("2011")
        expect(update_result.payment_method.expiration_date).to eq("07/2011")
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
        update_result = Braintree::PaymentMethod.update(credit_card.token,
          :cardholder_name => "New Holder",
          :cvv => "456",
          :number => Braintree::Test::CreditCardNumbers::FailsSandboxVerification::MasterCard,
          :expiration_date => "06/2013",
          :options => {:verify_card => true},
        )
        expect(update_result.success?).to eq(false)
        expect(update_result.credit_card_verification.status).to eq(Braintree::Transaction::Status::ProcessorDeclined)
        expect(update_result.credit_card_verification.gateway_rejection_reason).to be_nil
      end

      it "accepts a custom verification amount" do
        customer = Braintree::Customer.create!
        credit_card = Braintree::CreditCard.create!(
          :cardholder_name => "Card Holder",
          :customer_id => customer.id,
          :cvv => "123",
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2020",
        )
        update_result = Braintree::PaymentMethod.update(credit_card.token,
          :payment_method_nonce => Braintree::Test::Nonce::ProcessorDeclinedMasterCard,
          :options => {:verify_card => true, :verification_amount => "2.34"},
        )
        expect(update_result.success?).to eq(false)
        expect(update_result.credit_card_verification.status).to eq(Braintree::Transaction::Status::ProcessorDeclined)
        expect(update_result.credit_card_verification.gateway_rejection_reason).to be_nil
        expect(update_result.credit_card_verification.amount).to eq(BigDecimal("2.34"))
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
        result = Braintree::PaymentMethod.update(credit_card.token,
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
        address = result.payment_method.billing_address
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
        update_result = Braintree::PaymentMethod.update(credit_card.token,
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

        Braintree::PaymentMethod.update(card2.token, :options => {:make_default => true})

        expect(Braintree::CreditCard.find(card1.token)).not_to be_default
        expect(Braintree::CreditCard.find(card2.token)).to be_default
      end
    end

    context "paypal accounts" do
      it "updates a paypal account's token" do
        customer = Braintree::Customer.create!
        original_token = random_payment_method_token
        nonce = nonce_for_paypal_account(
          :consent_code => "consent-code",
          :token => original_token,
        )
        original_result = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
        )

        updated_token = make_token
        Braintree::PaymentMethod.update(
          original_token,
          :token => updated_token,
        )

        updated_paypal_account = Braintree::PayPalAccount.find(updated_token)
        expect(updated_paypal_account.email).to eq(original_result.payment_method.email)

        expect do
          Braintree::PayPalAccount.find(original_token)
        end.to raise_error(Braintree::NotFoundError, "payment method with token \"#{original_token}\" not found")
      end

      it "can make a paypal account the default payment method" do
        customer = Braintree::Customer.create!
        result = Braintree::CreditCard.create(
          :customer_id => customer.id,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009",
          :options => {:make_default => true},
        )
        expect(result).to be_success

        nonce = nonce_for_paypal_account(:consent_code => "consent-code")
        original_token = Braintree::PaymentMethod.create(
          :payment_method_nonce => nonce,
          :customer_id => customer.id,
        ).payment_method.token

        Braintree::PaymentMethod.update(
          original_token,
          :options => {:make_default => true},
        )

        updated_paypal_account = Braintree::PayPalAccount.find(original_token)
        expect(updated_paypal_account).to be_default
      end

      it "returns an error if a token for account is used to attempt an update" do
        customer = Braintree::Customer.create!
        first_token = random_payment_method_token
        second_token = random_payment_method_token

        first_nonce = nonce_for_paypal_account(
          :consent_code => "consent-code",
          :token => first_token,
        )
        Braintree::PaymentMethod.create(
          :payment_method_nonce => first_nonce,
          :customer_id => customer.id,
        )

        second_nonce = nonce_for_paypal_account(
          :consent_code => "consent-code",
          :token => second_token,
        )
        Braintree::PaymentMethod.create(
          :payment_method_nonce => second_nonce,
          :customer_id => customer.id,
        )

        updated_result = Braintree::PaymentMethod.update(
          first_token,
          :token => second_token,
        )

        expect(updated_result).not_to be_success
        expect(updated_result.errors.first.code).to eq("92906")
      end
    end
  end

  describe "self.update!" do
    it "updates the credit card" do
      customer = Braintree::Customer.create!
      credit_card = Braintree::CreditCard.create!(
        :cardholder_name => "Original Holder",
        :customer_id => customer.id,
        :cvv => "123",
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2012",
      )
      payment_method = Braintree::PaymentMethod.update!(credit_card.token,
        :cardholder_name => "New Holder",
        :cvv => "456",
        :number => Braintree::Test::CreditCardNumbers::MasterCard,
        :expiration_date => "06/2013",
      )
      expect(payment_method).to eq(credit_card)
      expect(payment_method.cardholder_name).to eq("New Holder")
      expect(payment_method.bin).to eq(Braintree::Test::CreditCardNumbers::MasterCard[0, 6])
      expect(payment_method.last_4).to eq(Braintree::Test::CreditCardNumbers::MasterCard[-4..-1])
      expect(payment_method.expiration_date).to eq("06/2013")
    end
  end

  context "payment method grant and revoke" do
    before(:each) do
      @partner_merchant_gateway = Braintree::Gateway.new(
        :merchant_id => "integration_merchant_public_id",
        :public_key => "oauth_app_partner_user_public_key",
        :private_key => "oauth_app_partner_user_private_key",
        :environment => Braintree::Configuration.environment,
        :logger => Logger.new("/dev/null"),
      )
      customer = @partner_merchant_gateway.customer.create(
        :first_name => "Joe",
        :last_name => "Brown",
        :company => "ExampleCo",
        :email => "joe@example.com",
        :phone => "312.555.1234",
        :fax => "614.555.5678",
        :website => "www.example.com",
      ).customer
      @credit_card = @partner_merchant_gateway.credit_card.create(
        :customer_id => customer.id,
        :cardholder_name => "Adam Davis",
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2009",
      ).credit_card

      @oauth_gateway = Braintree::Gateway.new(
        :client_id => "client_id$#{Braintree::Configuration.environment}$integration_client_id",
        :client_secret => "client_secret$#{Braintree::Configuration.environment}$integration_client_secret",
        :logger => Logger.new("/dev/null"),
      )
      access_token = Braintree::OAuthTestHelper.create_token(@oauth_gateway, {
        :merchant_public_id => "integration_merchant_id",
        :scope => "grant_payment_method"
      }).credentials.access_token

      @granting_gateway = Braintree::Gateway.new(
        :access_token => access_token,
        :logger => Logger.new("/dev/null"),
      )
    end

    describe "self.grant" do
      it "returns an error result when the grant doesn't succeed" do
        grant_result = @granting_gateway.payment_method.grant("payment_method_from_grant", true)
        expect(grant_result).not_to be_success
      end

      it "returns a nonce that is transactable by a partner merchant exactly once" do
        grant_result = @granting_gateway.payment_method.grant(@credit_card.token, :allow_vaulting => false)
        expect(grant_result).to be_success

        result = Braintree::Transaction.sale(
          :payment_method_nonce => grant_result.payment_method_nonce.nonce,
          :amount => Braintree::Test::TransactionAmounts::Authorize,
        )
        expect(result).to be_success

        result2 = Braintree::Transaction.sale(
          :payment_method_nonce => grant_result.payment_method_nonce.nonce,
          :amount => Braintree::Test::TransactionAmounts::Authorize,
        )
        expect(result2).not_to be_success
      end

      it "returns a nonce that is not vaultable" do
        grant_result = @granting_gateway.payment_method.grant(@credit_card.token, false)

        customer_result = Braintree::Customer.create()

        result = Braintree::PaymentMethod.create(
          :customer_id => customer_result.customer.id,
          :payment_method_nonce => grant_result.payment_method_nonce.nonce,
        )
        expect(result).not_to be_success
      end

      it "returns a nonce that is vaultable" do
        grant_result = @granting_gateway.payment_method.grant(@credit_card.token, :allow_vaulting => true)

        customer_result = Braintree::Customer.create()

        result = Braintree::PaymentMethod.create(
          :customer_id => customer_result.customer.id,
          :payment_method_nonce => grant_result.payment_method_nonce.nonce,
        )
        expect(result).to be_success
      end

      it "raises an error if the token isn't found" do
        expect do
          @granting_gateway.payment_method.grant("not_a_real_token", false)
        end.to raise_error(Braintree::NotFoundError)
      end

      it "returns a valid nonce with no options set" do
        expect do
          grant_result = @granting_gateway.payment_method.grant(@credit_card.token)
          expect(grant_result).to be_success
        end
      end
    end

    describe "self.revoke" do
      it "raises an error if the token isn't found" do
        expect do
          @granting_gateway.payment_method.revoke("not_a_real_token")
        end.to raise_error(Braintree::NotFoundError)
      end

      it "renders a granted nonce useless" do
        grant_result = @granting_gateway.payment_method.grant(@credit_card.token)
        revoke_result = @granting_gateway.payment_method.revoke(@credit_card.token)
        expect(revoke_result).to be_success

        customer_result = Braintree::Customer.create()

        result = Braintree::PaymentMethod.create(
          :customer_id => customer_result.customer.id,
          :payment_method_nonce => grant_result.payment_method_nonce.nonce,
        )
        expect(result).not_to be_success
      end

      it "renders a granted nonce obtained uisng options hash, useless" do
        grant_result = @granting_gateway.payment_method.grant(@credit_card.token, :allow_vaulting => true)
        revoke_result = @granting_gateway.payment_method.revoke(@credit_card.token)
        expect(revoke_result).to be_success

        customer_result = Braintree::Customer.create()

        result = Braintree::PaymentMethod.create(
          :customer_id => customer_result.customer.id,
          :payment_method_nonce => grant_result.payment_method_nonce.nonce,
        )
        expect(result).not_to be_success
      end
    end
  end
end
