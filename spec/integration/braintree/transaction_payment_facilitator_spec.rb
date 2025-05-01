require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::Transaction do

  describe "self.sale" do

    it "should create a transaction with sub merchant and payment facilitator for a payfac merchant" do
      transaction_params = {
        :type => "sale",
        :amount => "100.00",
        :merchant_account_id => SpecHelper::CardProcessorBRLPayFacMerchantAccountId,
        :credit_card => {
          :number => "4111111111111111",
          :expiration_date => "06/2026",
          :cvv => "123",
        },
        :descriptor => {
          :name => "companynme12*product12",
          :phone => "1232344444",
          :url => "example.com",
        },
        :billing => {
          :first_name => "Bob James",
          :country_code_alpha2 => "CA",
          :extended_address => "",
          :locality => "Trois-Rivires",
          :region => "QC",
          :postal_code => "G8Y 156",
          :street_address => "2346 Boul Lane",
        },
        :payment_facilitator => {
          :payment_facilitator_id => "98765432109",
          :sub_merchant => {
            :reference_number => "123456789012345",
            :tax_id => "99112233445577",
            :legal_name => "Fooda",
            :address => {
              :street_address => "10880 Ibitinga",
              :locality => "Araraquara",
              :region => "SP",
              :country_code_alpha2 => "BR",
              :postal_code => "13525000",
              :international_phone => {
                :country_code => "55",
                :national_number => "9876543210",
              },
            },
          },
        },
        :options => {
          :store_in_vault_on_success => true,
        },
      }

      result = Braintree::Transaction.sale(transaction_params)
      expect(result.success?).to eq(true)
      expect(result.transaction.status).to eq(Braintree::Transaction::Status::Authorized)
    end

    it "should fail on transaction with payment facilitator and non brazil merchant" do
      transaction_params = {
        :type => "sale",
        :amount => "100.00",
        :credit_card => {
          :number => "4111111111111111",
          :expiration_date => "06/2026",
          :cvv => "123",
        },
        :descriptor => {
          :name => "companynme12*product12",
          :phone => "1232344444",
          :url => "example.com",
        },
        :billing => {
          :first_name => "Bob James",
          :country_code_alpha2 => "CA",
          :extended_address => "",
          :locality => "Trois-Rivires",
          :region => "QC",
          :postal_code => "G8Y 156",
          :street_address => "2346 Boul Lane",
        },
        :payment_facilitator => {
          :payment_facilitator_id => "98765432109",
          :sub_merchant => {
            :reference_number => "123456789012345",
            :tax_id => "99112233445577",
            :legal_name => "Fooda",
            :address => {
              :street_address => "10880 Ibitinga",
              :locality => "Araraquara",
              :region => "SP",
              :country_code_alpha2 => "BR",
              :postal_code => "13525000",
              :international_phone => {
                :country_code => "55",
                :national_number => "9876543210",
              },
            },
          },
        },
        :options => {
          :store_in_vault_on_success => true,
        },
      }

      ezp_gateway = Braintree::Gateway.new(
        :environment => :development,
        :merchant_id => "pp_credit_ezp_merchant",
        :public_key => "pp_credit_ezp_merchant_public_key",
        :private_key => "pp_credit_ezp_merchant_private_key",
      )

      result = ezp_gateway.transaction.sale(transaction_params)
      expect(result.errors.for(:transaction).first.code).to eq(Braintree::ErrorCodes::PaymentFacilitator::PaymentFacilitatorNotApplicable)
    end
  end
end