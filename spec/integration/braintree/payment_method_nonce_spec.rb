require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")
require "date"

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
        },
      )

      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
      )

      expect(result).to be_success
      expect(result.payment_method).to be_a(Braintree::CreditCard)
      token = result.payment_method.token

      found_credit_card = Braintree::CreditCard.find(token)
      expect(found_credit_card).not_to be_nil

      result = Braintree::PaymentMethodNonce.create(found_credit_card.token)
      expect(result).to be_success
      expect(result.payment_method_nonce).not_to be_nil
      expect(result.payment_method_nonce.nonce).not_to be_nil
      expect(result.payment_method_nonce.details).not_to be_nil
      expect(result.payment_method_nonce.default?).to be_truthy
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
        },
      )

      payment_method = Braintree::PaymentMethod.create!(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
      )

      expect(payment_method).to be_a(Braintree::CreditCard)
      token = payment_method.token

      found_credit_card = Braintree::CreditCard.find(token)
      expect(found_credit_card).not_to be_nil

      payment_method_nonce = Braintree::PaymentMethodNonce.create!(found_credit_card.token)
      expect(payment_method_nonce).not_to be_nil
      expect(payment_method_nonce.nonce).not_to be_nil
      expect(payment_method_nonce.details).not_to be_nil
      expect(payment_method_nonce.default?).to be_truthy
    end
  end

  describe "self.find" do
    it "finds and returns the nonce if one was found" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-nonce")

      nonce = result.payment_method_nonce

      expect(result).to be_success
      expect(nonce.nonce).to eq("fake-valid-nonce")
      expect(nonce.type).to eq("CreditCard")
      expect(nonce.details.bin).to eq("401288")
      expect(nonce.details.card_type).to eq("Visa")
      expect(nonce.details.expiration_month).to eq("12")
      expect(nonce.details.expiration_year).to eq(Date.today.next_year.year.to_s)
      expect(nonce.details.is_network_tokenized?).to be_nil
      expect(nonce.details.last_two).to eq("81")
      expect(nonce.details.payer_info).to be_nil
    end

    it "return meta_checkout_card_details nonce if exist" do
      result = Braintree::PaymentMethodNonce.find(Braintree::Test::Nonce::MetaCheckoutCard)
      nonce = result.payment_method_nonce
      nonce.details.bin.should == "401288"
      nonce.details.last_two.should == "81"
      nonce.details.card_type.should == "Visa"
      nonce.details.expiration_year.should == Date.today().next_year().year.to_s
      nonce.details.expiration_month.should == "12"
    end

    it "return meta_checkout_token_details nonce if exist" do
      result = Braintree::PaymentMethodNonce.find(Braintree::Test::Nonce::MetaCheckoutToken)
      nonce = result.payment_method_nonce
      nonce.details.bin.should == "401288"
      nonce.details.last_two.should == "81"
      nonce.details.card_type.should == "Visa"
      nonce.details.expiration_year.should == Date.today().next_year().year.to_s
      nonce.details.expiration_month.should == "12"
    end

    it "return paypal details if details exist" do
      result = Braintree::PaymentMethodNonce.find("fake-paypal-one-time-nonce")
      nonce = result.payment_method_nonce
      expect(nonce.details.payer_info.billing_agreement_id).to be_nil
      expect(nonce.details.payer_info.country_code).to be_nil
      expect(nonce.details.payer_info.email).not_to be_nil
      expect(nonce.details.payer_info.first_name).not_to be_nil
      expect(nonce.details.payer_info.last_name).not_to be_nil
      expect(nonce.details.payer_info.payer_id).not_to be_nil
    end

    it "returns null 3ds_info if there isn't any" do
      nonce = nonce_for_new_payment_method(
        :credit_card => {
          :number => "4111111111111111",
          :expiration_month => "11",
          :expiration_year => "2099",
        },
      )

      result = Braintree::PaymentMethodNonce.find(nonce)

      nonce = result.payment_method_nonce

      expect(result).to be_success
      expect(nonce.three_d_secure_info).to be_nil
    end

    it "returns the bin" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-visa-nonce")

      nonce = result.payment_method_nonce
      expect(result).to be_success
      expect(nonce.details).not_to be_nil
      expect(nonce.details.bin).to eq("401288")
    end

    it "returns bin_data with commercial set to Yes" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-commercial-nonce")

      nonce = result.payment_method_nonce

      expect(result).to be_success
      expect(nonce.bin_data).not_to be_nil
      expect(nonce.bin_data.commercial).to eq(Braintree::CreditCard::Commercial::Yes)
    end

    it "returns bin_data with country_of_issuance set to CAN" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-country-of-issuance-cad-nonce")

      nonce = result.payment_method_nonce

      expect(result).to be_success
      expect(nonce.bin_data).not_to be_nil
      expect(nonce.bin_data.country_of_issuance).to eq("CAN")
    end

    it "returns bin_data with debit set to Yes" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-debit-nonce")

      nonce = result.payment_method_nonce

      expect(result).to be_success
      expect(nonce.bin_data).not_to be_nil
      expect(nonce.bin_data.debit).to eq(Braintree::CreditCard::Debit::Yes)
    end

    it "returns bin_data with durbin_regulated set to Yes" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-durbin-regulated-nonce")

      nonce = result.payment_method_nonce

      expect(result).to be_success
      expect(nonce.bin_data).not_to be_nil
      expect(nonce.bin_data.durbin_regulated).to eq(Braintree::CreditCard::DurbinRegulated::Yes)
    end

    it "returns bin_data with healthcare set to Yes" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-healthcare-nonce")

      nonce = result.payment_method_nonce

      expect(result).to be_success
      expect(nonce.bin_data).not_to be_nil
      expect(nonce.bin_data.healthcare).to eq(Braintree::CreditCard::Healthcare::Yes)
      expect(nonce.bin_data.product_id).to eq("J3")
    end

    it "returns bin_data with issuing_bank set to Network Only" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-issuing-bank-network-only-nonce")

      nonce = result.payment_method_nonce

      expect(result).to be_success
      expect(nonce.bin_data).not_to be_nil
      expect(nonce.bin_data.issuing_bank).to eq("NETWORK ONLY")
    end

    it "returns bin_data with payroll set to Yes" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-payroll-nonce")

      nonce = result.payment_method_nonce

      expect(result).to be_success
      expect(nonce.bin_data).not_to be_nil
      expect(nonce.bin_data.payroll).to eq(Braintree::CreditCard::Payroll::Yes)
      expect(nonce.bin_data.product_id).to eq("MSA")
    end

    it "returns bin_data with prepaid set to Yes" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-prepaid-nonce")

      nonce = result.payment_method_nonce

      expect(result).to be_success
      expect(nonce.bin_data).not_to be_nil
      expect(nonce.bin_data.prepaid).to eq(Braintree::CreditCard::Prepaid::Yes)
    end

    it "returns bin_data with prepaid_reloadable set to Yes" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-prepaid-reloadable-nonce")

      nonce = result.payment_method_nonce

      expect(result).to be_success
      expect(nonce.bin_data).not_to be_nil
      expect(nonce.bin_data.prepaid_reloadable).to eq(Braintree::CreditCard::PrepaidReloadable::Yes)
    end

    it "returns bin_data with unknown indicators" do
      result = Braintree::PaymentMethodNonce.find("fake-valid-unknown-indicators-nonce")

      nonce = result.payment_method_nonce

      expect(result).to be_success
      expect(nonce.bin_data).not_to be_nil
      expect(nonce.bin_data.commercial).to eq(Braintree::CreditCard::Commercial::Unknown)
      expect(nonce.bin_data.country_of_issuance).to eq(Braintree::CreditCard::CountryOfIssuance::Unknown)
      expect(nonce.bin_data.debit).to eq(Braintree::CreditCard::Debit::Unknown)
      expect(nonce.bin_data.durbin_regulated).to eq(Braintree::CreditCard::DurbinRegulated::Unknown)
      expect(nonce.bin_data.healthcare).to eq(Braintree::CreditCard::Healthcare::Unknown)
      expect(nonce.bin_data.issuing_bank).to eq(Braintree::CreditCard::IssuingBank::Unknown)
      expect(nonce.bin_data.payroll).to eq(Braintree::CreditCard::Payroll::Unknown)
      expect(nonce.bin_data.prepaid).to eq(Braintree::CreditCard::Prepaid::Unknown)
      expect(nonce.bin_data.prepaid_reloadable).to eq(Braintree::CreditCard::PrepaidReloadable::Unknown)
      expect(nonce.bin_data.product_id).to eq(Braintree::CreditCard::ProductId::Unknown)
    end

    it "correctly raises and exception for a non existent token" do
      expect do
        Braintree::PaymentMethodNonce.find("not_a_nonce")
      end.to raise_error(Braintree::NotFoundError)
    end

    context "authentication insights" do
      let(:indian_payment_token) { "india_visa_credit" }
      let(:european_payment_token) { "european_visa_credit" }
      let(:indian_merchant_token) { "india_three_d_secure_merchant_account" }
      let(:european_merchant_token) { "european_three_d_secure_merchant_account" }

      describe "self.create" do
        it "raises an exception if hash includes an invalid key" do
          expect do
            Braintree::PaymentMethodNonce.create("european_visa_credit", :invalid_key => "foo")
          end.to raise_error(ArgumentError, "invalid keys: invalid_key")
        end
      end

      context "regulation environments" do
        it "can get unregulated" do
          expect(
            request_authentication_insights(european_merchant_token, indian_payment_token)[:regulation_environment],
          ).to eq "unregulated"
        end

        it "can get psd2" do
          expect(
            request_authentication_insights(european_merchant_token, european_payment_token)[:regulation_environment],
          ).to eq "psd2"
        end

        it "can get rbi" do
          expect(
            request_authentication_insights(indian_merchant_token, indian_payment_token)[:regulation_environment],
          ).to eq "rbi"
        end
      end

      context "sca_indicator" do
        it "can get unavailable" do
          expect(
            request_authentication_insights(indian_merchant_token, indian_payment_token)[:sca_indicator],
          ).to eq "unavailable"
        end

        it "can get sca_required" do
          expect(
            request_authentication_insights(indian_merchant_token, indian_payment_token, {amount: 2001})[:sca_indicator],
          ).to eq "sca_required"
        end

        it "can get sca_optional" do
          expect(
            request_authentication_insights(indian_merchant_token, indian_payment_token, {amount: 2000, recurring_customer_consent: true, recurring_max_amount: 2000})[:sca_indicator],

          ).to eq "sca_optional"
        end
      end

      def request_authentication_insights(merchant_token, payment_method_token, options = {})
        authentication_insight_options = {
          amount: options[:amount],
          recurring_customer_consent: options[:recurring_customer_consent],
          recurring_max_amount: options[:recurring_max_amount],
        }
        nonce_request = {
          merchant_account_id: merchant_token,
          authentication_insight: true,
          authentication_insight_options: authentication_insight_options,
        }

        result = Braintree::PaymentMethodNonce.create(
          payment_method_token,
          payment_method_nonce: nonce_request,
        )
        expect(result).to be_success

        return result.payment_method_nonce.authentication_insight
      end
    end
  end
end
