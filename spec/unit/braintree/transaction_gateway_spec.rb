require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::TransactionGateway do
  describe "Transaction Gateway" do
    let(:gateway) do
      config = Braintree::Configuration.new(
        :merchant_id => "merchant_id",
        :public_key => "public_key",
        :private_key => "private_key",
      )
      Braintree::Gateway.new(config)
    end

    it "creates a transactionGateway gateway" do
      result = Braintree::TransactionGateway.new(gateway)

      expect(result.inspect).to include("merchant_id")
      expect(result.inspect).to include("public_key")
      expect(result.inspect).to include("private_key")
    end

    describe "self.create" do
      it "raises an exception if attributes contain an invalid key" do
        expect do
          transaction = Braintree::TransactionGateway.new(gateway)
          transaction.create(:invalid_key => "val")
        end.to raise_error(ArgumentError, "invalid keys: invalid_key")
      end
    end

    # NEXT_MAJOR_VERSION Remove three_d_secure_token, venmo_sdk_payment_method_code, and venmo_sdk_session
    # the old venmo SDK has been deprecated
    # three_d_secure_token has been deprecated in favor of three_d_secure_authentication_id
    it "creates a transaction gateway signature" do
      expect(Braintree::TransactionGateway._create_signature).to match([
        :amount, :billing_address_id, :channel, :currency_iso_code, :customer_id, :device_data,
        :discount_amount, :exchange_rate_quote_id, :foreign_retailer,
        :merchant_account_id, :order_id, :payment_method_nonce, :payment_method_token,
        :product_sku, :purchase_order_number, :service_fee_amount, :shared_billing_address_id,
        :shared_customer_id, :shared_payment_method_nonce, :shared_payment_method_token,
        :shared_shipping_address_id, :shipping_address_id, :shipping_amount, :shipping_tax_amount,
        :ships_from_postal_code, :tax_amount, :tax_exempt, :three_d_secure_authentication_id,:three_d_secure_token, #Deprecated
        :transaction_source, :type, :venmo_sdk_payment_method_code, # Deprecated
        :sca_exemption,
        {:apple_pay_card => [:number, :cardholder_name, :cryptogram, :expiration_month, :expiration_year, :eci_indicator]},
        {
          :billing => Braintree::AddressGateway._shared_signature
        },
        {:credit_card => [:token, :cardholder_name, :cvv, :expiration_date, :expiration_month, :expiration_year, :number, {:payment_reader_card_details => [:encrypted_card_data, :key_serial_number]}, {:network_tokenization_attributes => [:cryptogram, :ecommerce_indicator, :token_requestor_id]}]},
        {:customer => [:id, :company, :email, :fax, :first_name, :last_name, :phone, :website]},
        {:custom_fields => :_any_key_},
        {:descriptor => [:name, :phone, :url]},
        {:external_vault => [
          :status,
          :previous_network_transaction_id,
        ]},
        {:google_pay_card => [:number, :cryptogram, :google_transaction_id, :expiration_month, :expiration_year, :source_card_type, :source_card_last_four, :eci_indicator]},
        {:industry => [
          :industry_type,
          {:data => [
            :country_code, :date_of_birth, :folio_number, :check_in_date, :check_out_date, :travel_package, :lodging_check_in_date, :lodging_check_out_date, :departure_date, :lodging_name, :room_rate, :room_tax,
            :passenger_first_name, :passenger_last_name, :passenger_middle_initial, :passenger_title, :issued_date, :travel_agency_name, :travel_agency_code, :ticket_number,
            :issuing_carrier_code, :customer_code, :fare_amount, :fee_amount, :tax_amount, :restricted_ticket, :no_show, :advanced_deposit, :fire_safe, :property_phone, :ticket_issuer_address, :arrival_date,
            {:legs => [
              :conjunction_ticket, :exchange_ticket, :coupon_number, :service_class, :carrier_code, :fare_basis_code, :flight_number, :departure_date, :departure_airport_code, :departure_time,
              :arrival_airport_code, :arrival_time, :stopover_permitted, :fare_amount, :fee_amount, :tax_amount, :endorsement_or_restrictions,
            ]},
            {:additional_charges => [
              :kind, :amount,
            ]},
          ]},
        ]},
        {:installments => [:count]},
        {:line_items => [:commodity_code, :description, :discount_amount, :image_url, :kind, :name, :product_code, :quantity, :tax_amount, :total_amount, :unit_amount, :unit_of_measure, :unit_tax_amount, :upc_code, :upc_type, :url]},
        {:options => [
          :hold_in_escrow,
          :store_in_vault,
          :store_in_vault_on_success,
          :submit_for_settlement,
          :add_billing_address_to_payment_method,
          :store_shipping_address_in_vault,
          :venmo_sdk_session, # Deprecated
          :payee_id,
          :payee_email,
          :skip_advanced_fraud_checking,
          :skip_avs,
          :skip_cvv,
          {:paypal => [:custom_field, :payee_id, :payee_email, :description, {:supplementary_data => :_any_key_}]},
          {:processing_overrides => [:customer_email, :customer_first_name, :customer_last_name, :customer_tax_identifier]},
          {:three_d_secure => [:required]},
          {:amex_rewards => [:request_id, :points, :currency_amount, :currency_iso_code]},
          {:venmo => [:profile_id]},
          {:credit_card => [:account_type, :process_debit_as_credit]},
        ]
        },
        {:paypal_account => [:email, :token, :paypal_data, :payee_id, :payee_email, :payer_id, :payment_id]},
        {:risk_data => [:customer_browser, :customer_device_id, :customer_ip, :customer_location_zip, :customer_tenure]},
        {
          :shipping => Braintree::AddressGateway._shared_signature + [:shipping_method],
        },
        {
          :three_d_secure_pass_thru => [
            :eci_flag,
            :cavv,
            :xid,
            :three_d_secure_version,
            :authentication_response,
            :directory_response,
            :cavv_algorithm,
            :ds_transaction_id,
          ]
        },
      ])
    end

    it "creates a transaction gateway submit for settlement signature" do
      expect(Braintree::TransactionGateway._submit_for_settlement_signature).to match([
        :order_id,
        {:descriptor => [:name, :phone, :url]},
        {:industry => [
          :industry_type,
          {:data => [
            :country_code, :date_of_birth, :folio_number, :check_in_date, :check_out_date, :travel_package, :lodging_check_in_date, :lodging_check_out_date, :departure_date, :lodging_name, :room_rate, :room_tax,
            :passenger_first_name, :passenger_last_name, :passenger_middle_initial, :passenger_title, :issued_date, :travel_agency_name, :travel_agency_code, :ticket_number,
            :issuing_carrier_code, :customer_code, :fare_amount, :fee_amount, :tax_amount, :restricted_ticket, :no_show, :advanced_deposit, :fire_safe, :property_phone, :ticket_issuer_address, :arrival_date,
            {:legs => [
              :conjunction_ticket, :exchange_ticket, :coupon_number, :service_class, :carrier_code, :fare_basis_code, :flight_number, :departure_date, :departure_airport_code, :departure_time,
              :arrival_airport_code, :arrival_time, :stopover_permitted, :fare_amount, :fee_amount, :tax_amount, :endorsement_or_restrictions,
            ]},
            {:additional_charges => [
              :kind, :amount,
            ]},
          ]},
        ]},
        :purchase_order_number,
        :tax_amount,
        :tax_exempt,
        :discount_amount,
        :shipping_amount,
        :shipping_tax_amount,
        :ships_from_postal_code,
        :line_items => [:commodity_code, :description, :discount_amount, :image_url, :kind, :name, :product_code, :quantity, :tax_amount, :total_amount, :unit_amount, :unit_of_measure, :unit_tax_amount, :upc_code, :upc_type, :url],
      ])
    end

    it "creates transaction gateway submit for partial settlement signature" do
       expect(Braintree::TransactionGateway._submit_for_partial_settlement_signature).to include(:final_capture)
    end
  end
end
