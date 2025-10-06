require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::Transaction do
  describe "self.transfer type" do
    it "should create a transaction with valid transfer types and merchant account id" do
      transaction_params = {
        :type => "sale",
        :amount => "100.00",
        :merchant_account_id => "aft_first_data_wallet_transfer",
        :credit_card => {
          :number => "4111111111111111",
          :expiration_date => "06/2026",
          :cvv => "123"
        },
        :transfer => {
          :type => "wallet_transfer",
        },
      }

      result = Braintree::Transaction.sale(transaction_params)
      expect(result.success?).to eq(true)
      expect(result.transaction.account_funding_transaction).to eq(true)
      expect(result.transaction.status).to eq(Braintree::Transaction::Status::Authorized)
    end

    it "should fail on transaction with non brazil merchant" do
      transaction_params = {
        :type => "sale",
        :amount => "100.00",
        :merchant_account_id => "aft_first_data_wallet_transfer",
        :credit_card => {
          :number => "4111111111111111",
          :expiration_date => "06/2026",
          :cvv => "123"
        },
        :transfer => {
          :type => "invalid_transfer",
        },
      }

      result =  Braintree::Transaction.sale(transaction_params)
      expect(result.success?).to eq(false)
    end

    it "should create a transaction with valid transfer types and merchant account id" do
      SpecHelper::SdwoSupportedTransferTypes.each do |transfer_type|
        transaction_params = {
          :type => "sale",
          :amount => "100.00",
          :merchant_account_id => "card_processor_brl_sdwo",
          :credit_card => {
            :number => "4111111111111111",
            :expiration_date => "06/2026",
            :cvv => "123"
          },
          :descriptor => {
            :name => "companynme12*product1",
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
          :transfer => {
            :type => transfer_type,
            :sender => {
              :first_name => "Alice",
              :last_name => "Silva",
              :account_reference_number => "1000012345",
              :tax_id => "12345678900",
              :address => {
                :street_address => "Rua das Flores, 100",
                :extended_address => "2B",
                :locality => "São Paulo",
                :region => "SP",
                :postal_code => "01001-000",
                :country_code_alpha2 => "BR",
                :international_phone => {
                  :country_code => "55",
                  :national_number => "1234567890"
                }
              }
            },
            :receiver => {
              :first_name => "Bob",
              :last_name => "Souza",
              :account_reference_number => "2000012345",
              :tax_id => "98765432100",
              :address => {
                :street_address => "Avenida Brasil, 200",
                :extended_address => "2B",
                :locality => "Rio de Janeiro",
                :region => "RJ",
                :postal_code => "20040-002",
                :country_code_alpha2 => "BR",
                :international_phone => {
                  :country_code => "55",
                  :national_number => "9876543210"
                }
              }
            }
          },
          :options => {
            :store_in_vault_on_success => true,
          }
        }

        result = Braintree::Transaction.sale(transaction_params)
        expect(result.success?).to eq(true)
        expect(result.transaction.status).to eq(Braintree::Transaction::Status::Authorized)
      end
    end

    it "should fail when transfer details are not provided" do
      transaction_params = {
        :type => "sale",
        :amount => "100.00",
        :merchant_account_id => "card_processor_brl_sdwo",
        :credit_card => {
          :number => "4111111111111111",
          :expiration_date => "06/2026",
          :cvv => "123"
        },
        :descriptor => {
          :name => "companynme12*product1",
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
        :options => {
          :store_in_vault_on_success => true,
        }
      }

      result = Braintree::Transaction.sale(transaction_params)
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).first.code).to eq(Braintree::ErrorCodes::Transaction::TransactionTransferDetailsAreMandatory)
    end

    it "should fail on transaction with invalid transfer type" do
      transaction_params = {
        :type => "sale",
        :amount => "100.00",
        :merchant_account_id => "card_processor_brl_sdwo",
        :credit_card => {
          :number => "4111111111111111",
          :expiration_date => "06/2026",
          :cvv => "123"
        },
        :descriptor => {
          :name => "companynme12*product1",
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
        :transfer => {
          :type => "invalid_transfer_type",
          :sender => {
            :first_name => "Alice",
            :last_name => "Silva",
            :account_reference_number => "1000012345",
            :tax_id => "12345678900",
            :address => {
              :street_address => "Rua das Flores, 100",
              :extended_address => "2B",
              :locality => "São Paulo",
              :region => "SP",
              :postal_code => "01001-000",
              :country_code_alpha2 => "BR",
              :international_phone => {
                :country_code => "55",
                :national_number => "1234567890"
              }
            }
          },
          :receiver => {
            :first_name => "Bob",
            :last_name => "Souza",
            :account_reference_number => "2000012345",
            :tax_id => "98765432100",
            :address => {
              :street_address => "Avenida Brasil, 200",
              :extended_address => "2B",
              :locality => "Rio de Janeiro",
              :region => "RJ",
              :postal_code => "20040-002",
              :country_code_alpha2 => "BR",
              :international_phone => {
                :country_code => "55",
                :national_number => "9876543210"
              }
            }
          }
        },
        :options => {
          :store_in_vault_on_success => true,
        }
      }

      result =  Braintree::Transaction.sale(transaction_params)
      expect(result.success?).to eq(false)
      expect(result.errors.for(:account_funding_transaction).first.code).to eq(Braintree::ErrorCodes::Transaction::TransactionTransferTypeIsInvalid)
    end

    it "should create a transaction when transfer type is nil" do
      transaction_params = {
        :type => "sale",
        :amount => "100.00",
        :merchant_account_id => "card_processor_brl_sdwo",
        :credit_card => {
          :number => "4111111111111111",
          :expiration_date => "06/2026",
          :cvv => "123"
        },
        :descriptor => {
          :name => "companynme12*product1",
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
        :transfer => {
          :type => nil,
          :sender => {
            :first_name => "Alice",
            :last_name => "Silva",
            :account_reference_number => "1000012345",
            :tax_id => "12345678900",
            :address => {
              :street_address => "Rua das Flores, 100",
              :extended_address => "2B",
              :locality => "São Paulo",
              :region => "SP",
              :postal_code => "01001-000",
              :country_code_alpha2 => "BR",
              :international_phone => {
                :country_code => "55",
                :national_number => "1234567890"
              }
            }
          },
          :receiver => {
            :first_name => "Bob",
            :last_name => "Souza",
            :account_reference_number => "2000012345",
            :tax_id => "98765432100",
            :address => {
              :street_address => "Avenida Brasil, 200",
              :extended_address => "2B",
              :locality => "Rio de Janeiro",
              :region => "RJ",
              :postal_code => "20040-002",
              :country_code_alpha2 => "BR",
              :international_phone => {
                :country_code => "55",
                :national_number => "9876543210"
              }
            }
          }
        },
        :options => {
          :store_in_vault_on_success => true,
        }
      }

      result =  Braintree::Transaction.sale(transaction_params)
      expect(result.success?).to eq(true)
      expect(result.transaction.status).to eq(Braintree::Transaction::Status::Authorized)
    end
  end
end
