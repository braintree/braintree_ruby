require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::PaymentMethodNonce do
  let(:config) { Braintree::Configuration.instantiate }

  describe "self.create" do
    it "creates a payment method nonce from a vaulted credit card" do
      customer = Braintree::Customer.create.customer
      nonce = nonce_for_new_payment_method(
        :credit_card => {
          :number => "4111111111111111",
          :expiration_month => "11",
          :expiration_year => "2099",
        }
      )

      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id
      )

      result.should be_success
      result.payment_method.should be_a(Braintree::CreditCard)
      token = result.payment_method.token

      found_credit_card = Braintree::CreditCard.find(token)
      found_credit_card.should_not be_nil

      result = Braintree::PaymentMethodNonce.create(found_credit_card.token)
      result.should be_success
      result.payment_method_nonce.should_not be_nil
      result.payment_method_nonce.nonce.should_not be_nil
      result.payment_method_nonce.details.should_not be_nil
    end

    it "correctly raises and exception for a non existent token" do
      expect do
        Braintree::PaymentMethodNonce.create("not_a_token")
      end.to raise_error(Braintree::NotFoundError)
    end
  end

  describe "self.create!" do
    it "creates a payment method nonce from a vaulted credit card" do
      customer = Braintree::Customer.create.customer
      nonce = nonce_for_new_payment_method(
        :credit_card => {
          :number => "4111111111111111",
          :expiration_month => "11",
          :expiration_year => "2099",
        }
      )

      payment_method = Braintree::PaymentMethod.create!(
        :payment_method_nonce => nonce,
        :customer_id => customer.id
      )

      payment_method.should be_a(Braintree::CreditCard)
      token = payment_method.token

      found_credit_card = Braintree::CreditCard.find(token)
      found_credit_card.should_not be_nil

      payment_method_nonce = Braintree::PaymentMethodNonce.create!(found_credit_card.token)
      payment_method_nonce.should_not be_nil
      payment_method_nonce.nonce.should_not be_nil
      payment_method_nonce.details.should_not be_nil
    end
  end

  describe "self.find" do
    it "finds and returns the nonce if one was found" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-nonce")

      nonce = result.payment_method_nonce

      result.should be_success
      nonce.nonce.should == "fake-valid-nonce"
      nonce.type.should == "CreditCard"
      nonce.details.fetch(:last_two).should == "81"
      nonce.details.fetch(:card_type).should == "Visa"
    end

    it "return venmo details if details exist" do
      result = Braintree::PaymentMethodNonce.find("fake-venmo-account-nonce")

      nonce = result.payment_method_nonce

      nonce.details.fetch(:last_two).should == "99"
      nonce.details.fetch(:username).should == "venmojoe"
      nonce.details.fetch(:venmo_user_id).should == "Venmo-Joe-1"
    end

    it "returns null 3ds_info if there isn't any" do
      nonce = nonce_for_new_payment_method(
        :credit_card => {
          :number => "4111111111111111",
          :expiration_month => "11",
          :expiration_year => "2099",
        }
      )

      result = Braintree::PaymentMethodNonce.find(nonce)

      nonce = result.payment_method_nonce

      result.should be_success
      nonce.three_d_secure_info.should be_nil
    end

    it "returns the bin" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-visa-nonce")

      nonce = result.payment_method_nonce
      result.should be_success
      nonce.details.should_not be_nil
      nonce.details[:bin].should == "401288"
    end

    it "returns bin_data with commercial set to Yes" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-commercial-nonce")

      nonce = result.payment_method_nonce

      result.should be_success
      nonce.bin_data.should_not be_nil
      nonce.bin_data.commercial.should == Braintree::CreditCard::Commercial::Yes
    end

    it "returns bin_data with country_of_issuance set to CAN" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-country-of-issuance-cad-nonce")

      nonce = result.payment_method_nonce

      result.should be_success
      nonce.bin_data.should_not be_nil
      nonce.bin_data.country_of_issuance.should == "CAN"
    end

    it "returns bin_data with debit set to Yes" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-debit-nonce")

      nonce = result.payment_method_nonce

      result.should be_success
      nonce.bin_data.should_not be_nil
      nonce.bin_data.debit.should == Braintree::CreditCard::Debit::Yes
    end

    it "returns bin_data with durbin_regulated set to Yes" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-durbin-regulated-nonce")

      nonce = result.payment_method_nonce

      result.should be_success
      nonce.bin_data.should_not be_nil
      nonce.bin_data.durbin_regulated.should == Braintree::CreditCard::DurbinRegulated::Yes
    end

    it "returns bin_data with healthcare set to Yes" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-healthcare-nonce")

      nonce = result.payment_method_nonce

      result.should be_success
      nonce.bin_data.should_not be_nil
      nonce.bin_data.healthcare.should == Braintree::CreditCard::Healthcare::Yes
      nonce.bin_data.product_id.should == "J3"
    end

    it "returns bin_data with issuing_bank set to Network Only" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-issuing-bank-network-only-nonce")

      nonce = result.payment_method_nonce

      result.should be_success
      nonce.bin_data.should_not be_nil
      nonce.bin_data.issuing_bank.should == "NETWORK ONLY"
    end

    it "returns bin_data with payroll set to Yes" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-payroll-nonce")

      nonce = result.payment_method_nonce

      result.should be_success
      nonce.bin_data.should_not be_nil
      nonce.bin_data.payroll.should == Braintree::CreditCard::Payroll::Yes
      nonce.bin_data.product_id.should == "MSA"
    end

    it "returns bin_data with prepaid set to Yes" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-prepaid-nonce")

      nonce = result.payment_method_nonce

      result.should be_success
      nonce.bin_data.should_not be_nil
      nonce.bin_data.prepaid.should == Braintree::CreditCard::Prepaid::Yes
    end

    it "returns bin_data with unknown indicators" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-unknown-indicators-nonce")

      nonce = result.payment_method_nonce

      result.should be_success
      nonce.bin_data.should_not be_nil
      nonce.bin_data.commercial.should == Braintree::CreditCard::Commercial::Unknown
      nonce.bin_data.country_of_issuance.should == Braintree::CreditCard::CountryOfIssuance::Unknown
      nonce.bin_data.debit.should == Braintree::CreditCard::Debit::Unknown
      nonce.bin_data.durbin_regulated.should == Braintree::CreditCard::DurbinRegulated::Unknown
      nonce.bin_data.healthcare.should == Braintree::CreditCard::Healthcare::Unknown
      nonce.bin_data.issuing_bank.should == Braintree::CreditCard::IssuingBank::Unknown
      nonce.bin_data.payroll.should == Braintree::CreditCard::Payroll::Unknown
      nonce.bin_data.prepaid.should == Braintree::CreditCard::Prepaid::Unknown
      nonce.bin_data.product_id.should == Braintree::CreditCard::ProductId::Unknown
    end

    it "correctly raises and exception for a non existent token" do
      expect do
        Braintree::PaymentMethodNonce.find("not_a_nonce")
      end.to raise_error(Braintree::NotFoundError)
    end
  end
end
