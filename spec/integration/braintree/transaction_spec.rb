require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::Transaction do
  let(:industry_data_flight_params) do
    {
      :industry => {
        :industry_type => Braintree::Transaction::IndustryType::TravelAndFlight,
        :data => {
          :country_code => "US",
          :date_of_birth => "2012-12-12",
          :passenger_first_name => "John",
          :passenger_last_name => "Doe",
          :passenger_middle_initial => "M",
          :passenger_title => "Mr.",
          :issued_date => Date.new(2018, 1, 1),
          :travel_agency_name => "Expedia",
          :travel_agency_code => "12345678",
          :ticket_number => "ticket-number",
          :issuing_carrier_code => "AA",
          :customer_code => "customer-code",
          :fare_amount => 70_00,
          :fee_amount => 10_00,
          :tax_amount => 20_00,
          :restricted_ticket => false,
          :legs => [
            {
              :conjunction_ticket => "CJ0001",
              :exchange_ticket => "ET0001",
              :coupon_number => "1",
              :service_class => "Y",
              :carrier_code => "AA",
              :fare_basis_code => "W",
              :flight_number => "AA100",
              :departure_date => Date.new(2018, 1, 2),
              :departure_airport_code => "MDW",
              :departure_time => "08:00",
              :arrival_airport_code => "ATX",
              :arrival_time => "10:00",
              :stopover_permitted => false,
              :fare_amount => 35_00,
              :fee_amount => 5_00,
              :tax_amount => 10_00,
              :endorsement_or_restrictions => "NOT REFUNDABLE"
            },
            {
              :conjunction_ticket => "CJ0002",
              :exchange_ticket => "ET0002",
              :coupon_number => "1",
              :service_class => "Y",
              :carrier_code => "AA",
              :fare_basis_code => "W",
              :flight_number => "AA200",
              :departure_date => Date.new(2018, 1, 3),
              :departure_airport_code => "ATX",
              :departure_time => "12:00",
              :arrival_airport_code => "MDW",
              :arrival_time => "14:00",
              :stopover_permitted => false,
              :fare_amount => 35_00,
              :fee_amount => 5_00,
              :tax_amount => 10_00,
              :endorsement_or_restrictions => "NOT REFUNDABLE"
            }
          ]
        }
      },
    }
  end

  describe "self.clone_transaction" do
    it "creates a new transaction from the card of the transaction to clone" do
      result = Braintree::Transaction.sale(
        :amount => "112.44",
        :customer => {
          :last_name => "Adama",
        },
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
        :billing => {
          :country_name => "Botswana",
          :country_code_alpha2 => "BW",
          :country_code_alpha3 => "BWA",
          :country_code_numeric => "072"
        },
        :shipping => {
          :country_name => "Bhutan",
          :country_code_alpha2 => "BT",
          :country_code_alpha3 => "BTN",
          :country_code_numeric => "064"
        },
      )
      expect(result.success?).to eq(true)

      clone_result = Braintree::Transaction.clone_transaction(
        result.transaction.id,
        :amount => "112.44",
        :channel => "MyShoppingCartProvider",
        :options => {
          :submit_for_settlement => false
        },
      )
      expect(clone_result.success?).to eq(true)

      transaction = clone_result.transaction

      expect(transaction.id).not_to eq(result.transaction.id)
      expect(transaction.amount).to eq(BigDecimal("112.44"))
      expect(transaction.channel).to eq("MyShoppingCartProvider")

      expect(transaction.billing_details.country_name).to eq("Botswana")
      expect(transaction.billing_details.country_code_alpha2).to eq("BW")
      expect(transaction.billing_details.country_code_alpha3).to eq("BWA")
      expect(transaction.billing_details.country_code_numeric).to eq("072")

      expect(transaction.shipping_details.country_name).to eq("Bhutan")
      expect(transaction.shipping_details.country_code_alpha2).to eq("BT")
      expect(transaction.shipping_details.country_code_alpha3).to eq("BTN")
      expect(transaction.shipping_details.country_code_numeric).to eq("064")

      expect(transaction.credit_card_details.masked_number).to eq("510510******5100")
      expect(transaction.credit_card_details.expiration_date).to eq("05/2012")

      expect(transaction.customer_details.last_name).to eq("Adama")
      expect(transaction.status).to eq(Braintree::Transaction::Status::Authorized)
    end

    it "submit for settlement option" do
      result = Braintree::Transaction.sale(
        :amount => "112.44",
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
      )

      expect(result.success?).to be(true)

      clone_result = Braintree::Transaction.clone_transaction(result.transaction.id, :amount => "112.44", :options => {:submit_for_settlement => true})
      expect(clone_result.success?).to eq(true)

      expect(clone_result.transaction.status).to eq(Braintree::Transaction::Status::SubmittedForSettlement)
    end

    it "handles validation errors" do
      transaction = Braintree::Transaction.credit!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )
      result = Braintree::Transaction.clone_transaction(transaction.id, :amount => "112.44")
      expect(result.success?).to be(false)

      expect(result.errors.for(:transaction).on(:base).first.code).to eq(Braintree::ErrorCodes::Transaction::CannotCloneCredit)
    end
  end

  describe "self.clone_transaction!" do
    it "returns the transaction if valid" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )
      clone_transaction = Braintree::Transaction.clone_transaction!(transaction.id, :amount => "112.44", :options => {:submit_for_settlement => false})
      expect(clone_transaction.id).not_to eq(transaction.id)
    end

    it "raises a validationsfailed if invalid" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )
      expect do
        clone_transaction = Braintree::Transaction.clone_transaction!(transaction.id, :amount => "im not a number")
        expect(clone_transaction.id).not_to eq(transaction.id)
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.create" do
    describe "risk data" do
      it "returns decision, device_data_captured, id, transaction_risk_score, and decision_reasons" do
        with_fraud_protection_enterprise_merchant do
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => 1_00,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::CardTypeIndicators::Prepaid,
              :expiration_date => "05/2009"
            },
          )
          expect(result.transaction.risk_data).to be_a(Braintree::RiskData)
          expect(result.transaction.risk_data.id).not_to be_nil
          expect(result.transaction.risk_data.decision).not_to be_nil
          expect(result.transaction.risk_data.decision_reasons).not_to be_nil
          expect(result.transaction.risk_data).to respond_to(:device_data_captured)
          expect(result.transaction.risk_data).to respond_to(:fraud_service_provider)
          expect(result.transaction.risk_data).to respond_to(:transaction_risk_score)
        end
      end

      it "returns decision, device_data_captured, id, liability_shift, and decision_reasons" do
        with_chargeback_protection_merchant do
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => 1_00,
            :credit_card => {
              :number => "4111111111111111",
              :expiration_date => "05/2009"
            },
          )
          expect(result.transaction.risk_data).to be_a(Braintree::RiskData)
          expect(result.transaction.risk_data.id).not_to be_nil
          expect(result.transaction.risk_data.decision).not_to be_nil
          expect(result.transaction.risk_data.decision_reasons).not_to be_nil
          expect(result.transaction.risk_data).to respond_to(:device_data_captured)
          expect(result.transaction.risk_data).to respond_to(:fraud_service_provider)
          expect(result.transaction.risk_data).to respond_to(:liability_shift)
        end
      end

      it "handles validation errors for invalid risk data attributes" do
        with_advanced_fraud_kount_integration_merchant do
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "05/2009"
            },
            :risk_data => {
              :customer_browser => "#{"1" * 300}",
              :customer_device_id => "customer_device_id_0#{"1" * 300}",
              :customer_ip => "192.168.0.1",
              :customer_location_zip => "not-a-$#phone",
              :customer_tenure => "20#{"0" * 500}"
            },
          )
          expect(result.success?).to eq(false)
          expect(result.errors.for(:transaction).for(:risk_data).on(:customer_device_id).map { |e| e.code }).to include Braintree::ErrorCodes::RiskData::CustomerDeviceIdIsTooLong
          expect(result.errors.for(:transaction).for(:risk_data).on(:customer_location_zip).map { |e| e.code }).to include Braintree::ErrorCodes::RiskData::CustomerLocationZipInvalidCharacters
          expect(result.errors.for(:transaction).for(:risk_data).on(:customer_tenure).map { |e| e.code }).to include Braintree::ErrorCodes::RiskData::CustomerTenureIsTooLong
        end
      end
    end

    describe "card type indicators" do
      it "sets the prepaid field if the card is prepaid" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => 1_00,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::CardTypeIndicators::Prepaid,
            :expiration_date => "05/2009"
          },
        )
        expect(result.transaction.credit_card_details.prepaid).to eq(Braintree::CreditCard::Prepaid::Yes)
        expect(result.transaction.payment_instrument_type).to eq(Braintree::PaymentInstrumentType::CreditCard)
      end
    end

    describe "sca_exemption" do
      context "with a valid request" do
        it "succeeds" do
          requested_exemption = "low_value"
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::VisaCountryOfIssuanceIE,
              :expiration_date => "05/2009"
            },
            :sca_exemption => requested_exemption,
          )
          expect(result).to be_success
          expect(result.transaction.sca_exemption_requested).to eq(requested_exemption)
        end
      end

      context "with an invalid request" do
        it "returns an error" do
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "05/2009"
            },
            :sca_exemption => "invalid_sca_exemption_value",
          )
          sca_exemption_invalid = Braintree::ErrorCodes::Transaction::ScaExemptionInvalid
          expect(result).not_to be_success
          expect(result.errors.for(:transaction).map(&:code)).to eq([sca_exemption_invalid])
        end
      end
    end

    describe "industry data" do
      context "for lodging" do
        it "accepts valid industry data" do
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => 1000_00,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::CardTypeIndicators::Prepaid,
              :expiration_date => "05/2009"
            },
            :industry => {
              :industry_type => Braintree::Transaction::IndustryType::Lodging,
              :data => {
                :folio_number => "ABCDEFG",
                :check_in_date => "2014-06-01",
                :check_out_date => "2014-06-05",
                :room_rate => 170_00,
                :room_tax => 30_00,
                :no_show => false,
                :advanced_deposit => false,
                :fire_safe => true,
                :property_phone => "1112223345",
                :additional_charges => [
                  {
                    :kind => Braintree::Transaction::AdditionalCharge::Telephone,
                    :amount => 50_00,
                  },
                  {
                    :kind => Braintree::Transaction::AdditionalCharge::Other,
                    :amount => 150_00,
                  },
                ],
              }
            },
          )
          expect(result.success?).to be(true)
        end

        it "returns errors if validations on industry lodging data fails" do
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => 500_00,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::CardTypeIndicators::Prepaid,
              :expiration_date => "05/2009"
            },
            :industry => {
              :industry_type => Braintree::Transaction::IndustryType::Lodging,
              :data => {
                :folio_number => "foo bar",
                :check_in_date => "2014-06-30",
                :check_out_date => "2014-06-01",
                :room_rate => "asdfasdf",
                :additional_charges => [
                  {
                    :kind => "unknown",
                    :amount => 20_00,
                  },
                ],
              }
            },
          )
          expect(result.success?).to be(false)
          invalid_folio = Braintree::ErrorCodes::Transaction::Industry::Lodging::FolioNumberIsInvalid
          check_out_date_must_follow_check_in_date = Braintree::ErrorCodes::Transaction::Industry::Lodging::CheckOutDateMustFollowCheckInDate
          room_rate_format_is_invalid = Braintree::ErrorCodes::Transaction::Industry::Lodging::RoomRateFormatIsInvalid
          invalid_additional_charge_kind = Braintree::ErrorCodes::Transaction::Industry::AdditionalCharge::KindIsInvalid
          expect(result.errors.for(:transaction).for(:industry).map { |e| e.code }.sort).to include(invalid_folio, check_out_date_must_follow_check_in_date, room_rate_format_is_invalid)
          expect(result.errors.for(:transaction).for(:industry).for(:additional_charges).for(:index_0).on(:kind).map { |e| e.code }.sort).to include(invalid_additional_charge_kind)
        end
      end

      context "for travel cruise" do
        it "accepts valid industry data" do
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => 1_00,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::CardTypeIndicators::Prepaid,
              :expiration_date => "05/2009"
            },
            :industry => {
              :industry_type => Braintree::Transaction::IndustryType::TravelAndCruise,
              :data => {
                :travel_package => "flight",
                :departure_date => "2014-07-01",
                :lodging_check_in_date => "2014-07-07",
                :lodging_check_out_date => "2014-07-07",
                :lodging_name => "Royal Caribbean",
              }
            },
          )
          expect(result.success?).to be(true)
        end

        it "returns errors if validations on industry data fails" do
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => 1_00,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::CardTypeIndicators::Prepaid,
              :expiration_date => "05/2009"
            },
            :industry => {
              :industry_type => Braintree::Transaction::IndustryType::TravelAndCruise,
              :data => {
                :lodging_name => "Royal Caribbean"
              }
            },
          )
          expect(result.success?).to be(false)
          expect(result.errors.for(:transaction).for(:industry).map { |e| e.code }.sort).to eq([Braintree::ErrorCodes::Transaction::Industry::TravelCruise::TravelPackageIsInvalid])
        end
      end

      context "for travel flight" do
        it "accepts valid industry data" do
          params = {
            :type => "sale",
            :amount => 1_00,
            :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
            :options => {
              :submit_for_settlement => true
            },
          }
          params.merge(industry_data_flight_params)

          result = Braintree::Transaction.create(params)
          result.success?.should be(true)
        end

        it "returns errors if validations on industry data fails" do
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => 1_00,
            :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
            :options => {
              :submit_for_settlement => true
            },
            :industry => {
              :industry_type => Braintree::Transaction::IndustryType::TravelAndFlight,
              :data => {
                :fare_amount => -1_23,
                :restricted_ticket => false,
                :legs => [
                  {
                    :fare_amount => -1_23
                  }
                ]
              }
            },
          )
          expect(result.success?).to be(false)
          expect(result.errors.for(:transaction).for(:industry).map { |e| e.code }.sort).to eq([Braintree::ErrorCodes::Transaction::Industry::TravelFlight::FareAmountCannotBeNegative])
          expect(result.errors.for(:transaction).for(:industry).for(:legs).for(:index_0).map { |e| e.code }.sort).to eq([Braintree::ErrorCodes::Transaction::Industry::Leg::TravelFlight::FareAmountCannotBeNegative])
        end

        [Braintree::Test::CreditCardNumbers::Discover, Braintree::Test::CreditCardNumbers::Visa].each do |card_number|
          it "accepts valid industry data for card : #{card_number} " do
            result = Braintree::Transaction.create(
              :type => "sale",
              :merchant_account_id => SpecHelper::FakeFirstDataMerchantAccountId,
              :amount => 1_00,
              :credit_card => {
              :number => card_number,
              :expiration_date => "05/2029"
              },
              :options => {
                :submit_for_settlement => true
              },
              :industry => {
                :industry_type => Braintree::Transaction::IndustryType::TravelAndFlight,
                :data => {
                  :passenger_first_name => "John",
                  :passenger_last_name => "Doe",
                  :passenger_middle_initial => "M",
                  :passenger_title => "Mr.",
                  :issued_date => Date.new(2018, 1, 1),
                  :travel_agency_name => "Expedia",
                  :travel_agency_code => "12345678",
                  :ticket_number => "ticket-number",
                  :issuing_carrier_code => "AA",
                  :customer_code => "customer-code",
                  :fare_amount => 70_00,
                  :fee_amount => 10_00,
                  :tax_amount => 20_00,
                  :ticket_issuer_address => "Tkt-issuer-adr",
                  :arrival_date => Date.new(2018, 1, 2),
                  :restricted_ticket => false,
                  :legs => [
                    {
                      :conjunction_ticket => "CJ0001",
                      :exchange_ticket => "ET0001",
                      :coupon_number => "1",
                      :service_class => "Y",
                      :carrier_code => "AA",
                      :fare_basis_code => "W",
                      :flight_number => "AA100",
                      :departure_date => Date.new(2018, 1, 2),
                      :departure_airport_code => "MDW",
                      :departure_time => "08:00",
                      :arrival_airport_code => "AUS",
                      :arrival_time => "10:00",
                      :stopover_permitted => false,
                      :fare_amount => 35_00,
                      :fee_amount => 5_00,
                      :tax_amount => 10_00,
                      :endorsement_or_restrictions => "NOT REFUNDABLE"
                    }
                  ]
                }
              },
            )
            expect(result.success?).to be(true)
          end


          it "2 step should be processed with AID(Airline Industry data) in step 1" do
            result = Braintree::Transaction.create(
              :type => "sale",
              :merchant_account_id => SpecHelper::FakeFirstDataMerchantAccountId,
              :amount => 1_00,
              :credit_card => {
                :number => card_number,
                :expiration_date => "05/2029"
              },
              :industry => {
                :industry_type => Braintree::Transaction::IndustryType::TravelAndFlight,
                :data => {
                  :passenger_first_name => "John",
                  :passenger_last_name => "Doe",
                  :passenger_middle_initial => "M",
                  :passenger_title => "Mr.",
                  :issued_date => Date.new(2020, 1, 1),
                  :travel_agency_name => "Expedia",
                  :travel_agency_code => "12345678",
                  :ticket_number => "ticket-number",
                  :issuing_carrier_code => "AA",
                  :customer_code => "customer-code",
                  :fare_amount => 70_00,
                  :fee_amount => 10_00,
                  :tax_amount => 20_00,
                  :ticket_issuer_address => "Tkt-issuer-adr",
                  :arrival_date => Date.new(2020, 1, 1),
                  :restricted_ticket => false,
                  :legs => [
                    {
                      :conjunction_ticket => "CJ0001",
                      :exchange_ticket => "ET0001",
                      :coupon_number => "1",
                      :service_class => "Y",
                      :carrier_code => "AA",
                      :fare_basis_code => "W",
                      :flight_number => "AA100",
                      :departure_date => Date.new(2018, 1, 2),
                      :departure_airport_code => "MDW",
                      :departure_time => "08:00",
                      :arrival_airport_code => "ABC",
                      :arrival_time => "10:00",
                      :stopover_permitted => false,
                      :fare_amount => 35_00,
                      :fee_amount => 5_00,
                      :tax_amount => 10_00,
                      :endorsement_or_restrictions => "NOT REFUNDABLE"
                    }
                  ]
                }
              },
            )
            expect(result.success?).to be(true)
            expect(result.transaction.status).to eq(Braintree::Transaction::Status::Authorized)

            result = Braintree::Transaction.submit_for_settlement(result.transaction.id)

            expect(result.success?).to eq(true)
            expect(result.transaction.status).to eq(Braintree::Transaction::Status::SubmittedForSettlement)
          end

          it "2 step should be processed with AID in step 2" do
            result = Braintree::Transaction.create(
              :type => "sale",
              :merchant_account_id => SpecHelper::FakeFirstDataMerchantAccountId,
              :amount => 1_00,
              :credit_card => {
                :number => card_number,
                :expiration_date => "05/2029",
              },
            )

            expect(result.success?).to be(true)
            expect(result.transaction.status).to eq(Braintree::Transaction::Status::Authorized)

            options = {:industry => {
              :industry_type => Braintree::Transaction::IndustryType::TravelAndFlight,
              :data => {
                :passenger_first_name => "John",
                :passenger_last_name => "Doe",
                :passenger_middle_initial => "M",
                :passenger_title => "Mr.",
                :issued_date => Date.new(2018, 1, 1),
                :travel_agency_name => "Expedia",
                :travel_agency_code => "12345678",
                :ticket_number => "ticket-number",
                :issuing_carrier_code => "AA",
                :customer_code => "customer-code",
                :fare_amount => 70_00,
                :fee_amount => 10_00,
                :tax_amount => 20_00,
                :ticket_issuer_address => "Tkt-issuer-adr",
                :arrival_date => Date.new(2020, 1, 1),
                :restricted_ticket => false,
                :legs => [
                  {
                    :conjunction_ticket => "CJ0001",
                    :exchange_ticket => "ET0001",
                    :coupon_number => "1",
                    :service_class => "Y",
                    :carrier_code => "AA",
                    :fare_basis_code => "W",
                    :flight_number => "AA100",
                    :departure_date => Date.new(2018, 1, 2),
                    :departure_airport_code => "MDW",
                    :departure_time => "08:00",
                    :arrival_airport_code => "ABC",
                    :arrival_time => "10:00",
                    :stopover_permitted => false,
                    :fare_amount => 35_00,
                    :fee_amount => 5_00,
                    :tax_amount => 10_00,
                    :endorsement_or_restrictions => "NOT REFUNDABLE"
                  }
                ]
              }
            }
            }

            result = Braintree::Transaction.submit_for_settlement(result.transaction.id, nil, options)

            expect(result.success?).to eq(true)
            expect(result.transaction.status).to eq(Braintree::Transaction::Status::SubmittedForSettlement)
          end

          it "should not be processed with AID if validations on industry data fails for card : #{card_number}" do
            result = Braintree::Transaction.create(
              :type => "sale",
              :merchant_account_id => SpecHelper::FakeFirstDataMerchantAccountId,
              :amount => 1_00,
              :credit_card => {
                :number => card_number,
                :expiration_date => "05/2029"
              },
              :options => {
                :submit_for_settlement => true
              },
              :industry => {
                :industry_type => Braintree::Transaction::IndustryType::TravelAndFlight,
                :data => {
                  :passenger_middle_initial => "CD",
                  :fare_amount => -1_23,
                  :issuing_carrier_code => "-AA",
                  :restricted_ticket => false,
                  :ticket_number => "A" * 30,
                  :legs => [
                    {
                      :conjunction_ticket => "C"*25,
                      :fare_amount => -1_23,
                      :carrier_code => ".AA",
                    }
                  ]
                }
              },
            )
          expect(result.success?).to be(false)
          expect([
            Braintree::ErrorCodes::Transaction::Industry::TravelFlight::FareAmountCannotBeNegative,
            Braintree::ErrorCodes::Transaction::Industry::TravelFlight::PassengerMiddleInitialIsTooLong,
            Braintree::ErrorCodes::Transaction::Industry::TravelFlight::TicketNumberIsTooLong,
          ]).to include(*result.errors.for(:transaction).for(:industry).map { |e| e.code }.sort)
          expect([
            Braintree::ErrorCodes::Transaction::Industry::Leg::TravelFlight::CarrierCodeIsTooLong,
            Braintree::ErrorCodes::Transaction::Industry::Leg::TravelFlight::FareAmountCannotBeNegative,
            Braintree::ErrorCodes::Transaction::Industry::Leg::TravelFlight::ConjunctionTicketIsTooLong,
          ]).to include(*result.errors.for(:transaction).for(:industry).for(:legs).for(:index_0).map { |e| e.code }.sort)
          end
        end
      end
    end

    context "elo" do
      it "returns a successful result if successful" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :merchant_account_id => SpecHelper::AdyenMerchantAccountId,
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Elo,
            :cvv => "737",
            :expiration_date => "10/2020"
          },
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.id).to match(/^\w{6,}$/)
        expect(result.transaction.type).to eq("sale")
        expect(result.transaction.amount).to eq(BigDecimal(Braintree::Test::TransactionAmounts::Authorize))
        expect(result.transaction.processor_authorization_code).not_to be_nil
        expect(result.transaction.voice_referral_number).to be_nil
        expect(result.transaction.credit_card_details.bin).to eq(Braintree::Test::CreditCardNumbers::Elo[0, 6])
        expect(result.transaction.credit_card_details.last_4).to eq(Braintree::Test::CreditCardNumbers::Elo[-4..-1])
        expect(result.transaction.credit_card_details.expiration_date).to eq("10/2020")
        expect(result.transaction.credit_card_details.customer_location).to eq("US")
      end
    end

    context "foreign_retailer" do
      it "returns true when foreign_retailer param is true" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2025"
          },
          :foreign_retailer => true,
        )
        expect(result).to be_success
        expect(result.transaction.foreign_retailer).to be_truthy
      end

      it "returns nil when foreign_retailer param is false" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2025"
          },
          :foreign_retailer => false,
        )
        expect(result).to be_success
        expect(result.transaction.foreign_retailer).to be_nil
      end

      it "returns nil when foreign_retailer param is nil" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2025"
          },
        )
        expect(result).to be_success
        expect(result.transaction.foreign_retailer).to be_nil
      end
    end

    it "returns a successful result if successful" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )
      expect(result.success?).to eq(true)
      expect(result.transaction.id).to match(/^\w{6,}$/)
      expect(result.transaction.type).to eq("sale")
      expect(result.transaction.amount).to eq(BigDecimal(Braintree::Test::TransactionAmounts::Authorize))
      expect(result.transaction.processor_authorization_code).not_to be_nil
      expect(result.transaction.processor_response_code).to eq("1000")
      expect(result.transaction.processor_response_text).to eq("Approved")
      expect(result.transaction.processor_response_type).to eq(Braintree::ProcessorResponseTypes::Approved)
      expect(result.transaction.voice_referral_number).to be_nil
      expect(result.transaction.credit_card_details.bin).to eq(Braintree::Test::CreditCardNumbers::Visa[0, 6])
      expect(result.transaction.credit_card_details.last_4).to eq(Braintree::Test::CreditCardNumbers::Visa[-4..-1])
      expect(result.transaction.credit_card_details.expiration_date).to eq("05/2009")
      expect(result.transaction.credit_card_details.customer_location).to eq("US")
      expect(result.transaction.retrieval_reference_number).not_to be_nil
      expect(result.transaction.acquirer_reference_number).to be_nil
    end

    it "returns a successful network response code if successful" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )
      expect(result.success?).to eq(true)
      expect(result.transaction.type).to eq("sale")
      expect(result.transaction.amount).to eq(BigDecimal(Braintree::Test::TransactionAmounts::Authorize))
      expect(result.transaction.processor_authorization_code).not_to be_nil
      expect(result.transaction.processor_response_code).to eq("1000")
      expect(result.transaction.processor_response_text).to eq("Approved")
      expect(result.transaction.processor_response_type).to eq(Braintree::ProcessorResponseTypes::Approved)
      expect(result.transaction.network_response_code).to eq("XX")
      expect(result.transaction.network_response_text).to eq("sample network response text")
      expect(result.transaction.voice_referral_number).to be_nil
      expect(result.transaction.credit_card_details.bin).to eq(Braintree::Test::CreditCardNumbers::Visa[0, 6])
      expect(result.transaction.credit_card_details.last_4).to eq(Braintree::Test::CreditCardNumbers::Visa[-4..-1])
      expect(result.transaction.credit_card_details.expiration_date).to eq("05/2009")
      expect(result.transaction.credit_card_details.customer_location).to eq("US")
    end

    it "returns a successful result using an access token" do
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

      result = gateway.transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )

      expect(result.success?).to eq(true)
      expect(result.transaction.id).to match(/^\w{6,}$/)
      expect(result.transaction.type).to eq("sale")
      expect(result.transaction.amount).to eq(BigDecimal(Braintree::Test::TransactionAmounts::Authorize))
      expect(result.transaction.processor_authorization_code).not_to be_nil
      expect(result.transaction.voice_referral_number).to be_nil
      expect(result.transaction.credit_card_details.bin).to eq(Braintree::Test::CreditCardNumbers::Visa[0, 6])
      expect(result.transaction.credit_card_details.last_4).to eq(Braintree::Test::CreditCardNumbers::Visa[-4..-1])
      expect(result.transaction.credit_card_details.expiration_date).to eq("05/2009")
      expect(result.transaction.credit_card_details.customer_location).to eq("US")
    end

    it "accepts additional security parameters: device_data" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
        :device_data => "device_data",
      )

      expect(result.success?).to eq(true)
    end

    it "accepts additional security parameters: risk data" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
        :risk_data => {
          :customer_browser => "IE6",
          :customer_device_id => "customer_device_id_012",
          :customer_ip => "192.168.0.1",
          :customer_location_zip => "91244",
          :customer_tenure => "20",
        },
      )

      expect(result.success?).to eq(true)
    end

    it "accepts billing_address_id in place of billing_address" do
      result = Braintree::Customer.create()
      address_result = Braintree::Address.create(
        :customer_id => result.customer.id,
        :country_code_alpha2 => "US",
      )

      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :customer_id => result.customer.id,
        :billing_address_id => address_result.address.id,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )

      expect(result.success?).to eq(true)
    end

    it "returns processor response code and text as well as the additional processor response if soft declined" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )
      expect(result.success?).to eq(false)
      expect(result.transaction.id).to match(/^\w{6,}$/)
      expect(result.transaction.type).to eq("sale")
      expect(result.transaction.status).to eq(Braintree::Transaction::Status::ProcessorDeclined)
      expect(result.transaction.processor_response_code).to eq("2000")
      expect(result.transaction.processor_response_text).to eq("Do Not Honor")
      expect(result.transaction.processor_response_type).to eq(Braintree::ProcessorResponseTypes::SoftDeclined)
      expect(result.transaction.additional_processor_response).to eq("2000 : Do Not Honor")
    end

    it "returns processor response code and text as well as the additional processor response if hard declined" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::HardDecline,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )
      expect(result.success?).to eq(false)
      expect(result.transaction.id).to match(/^\w{6,}$/)
      expect(result.transaction.type).to eq("sale")
      expect(result.transaction.status).to eq(Braintree::Transaction::Status::ProcessorDeclined)
      expect(result.transaction.processor_response_code).to eq("2015")
      expect(result.transaction.processor_response_text).to eq("Transaction Not Allowed")
      expect(result.transaction.processor_response_type).to eq(Braintree::ProcessorResponseTypes::HardDeclined)
      expect(result.transaction.additional_processor_response).to eq("2015 : Transaction Not Allowed")
    end

    it "accepts all four country codes" do
      result = Braintree::Transaction.sale(
        :amount => "100",
        :customer => {
          :last_name => "Adama",
        },
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
        :billing => {
          :country_name => "Botswana",
          :country_code_alpha2 => "BW",
          :country_code_alpha3 => "BWA",
          :country_code_numeric => "072"
        },
        :shipping => {
          :country_name => "Bhutan",
          :country_code_alpha2 => "BT",
          :country_code_alpha3 => "BTN",
          :country_code_numeric => "064"
        },
        :options => {
          :add_billing_address_to_payment_method => true,
          :store_in_vault => true
        },
      )
      expect(result.success?).to eq(true)
      transaction = result.transaction
      expect(transaction.billing_details.country_name).to eq("Botswana")
      expect(transaction.billing_details.country_code_alpha2).to eq("BW")
      expect(transaction.billing_details.country_code_alpha3).to eq("BWA")
      expect(transaction.billing_details.country_code_numeric).to eq("072")

      expect(transaction.shipping_details.country_name).to eq("Bhutan")
      expect(transaction.shipping_details.country_code_alpha2).to eq("BT")
      expect(transaction.shipping_details.country_code_alpha3).to eq("BTN")
      expect(transaction.shipping_details.country_code_numeric).to eq("064")

      expect(transaction.vault_credit_card.billing_address.country_name).to eq("Botswana")
      expect(transaction.vault_credit_card.billing_address.country_code_alpha2).to eq("BW")
      expect(transaction.vault_credit_card.billing_address.country_code_alpha3).to eq("BWA")
      expect(transaction.vault_credit_card.billing_address.country_code_numeric).to eq("072")
    end

    it "returns an error if provided inconsistent country information" do
      result = Braintree::Transaction.sale(
        :amount => "100",
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
        :billing => {
          :country_name => "Botswana",
          :country_code_alpha2 => "US",
        },
      )

      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).for(:billing).on(:base).map { |e| e.code }).to include(Braintree::ErrorCodes::Address::InconsistentCountry)
    end

    it "returns an error if given an incorrect alpha2 code" do
      result = Braintree::Transaction.sale(
        :amount => "100",
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
        :billing => {
          :country_code_alpha2 => "ZZ"
        },
      )

      expect(result.success?).to eq(false)
      codes = result.errors.for(:transaction).for(:billing).on(:country_code_alpha2).map { |e| e.code }
      expect(codes).to include(Braintree::ErrorCodes::Address::CountryCodeAlpha2IsNotAccepted)
    end

    it "returns an error if given an incorrect alpha3 code" do
      result = Braintree::Transaction.sale(
        :amount => "100",
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
        :billing => {
          :country_code_alpha3 => "ZZZ"
        },
      )

      expect(result.success?).to eq(false)
      codes = result.errors.for(:transaction).for(:billing).on(:country_code_alpha3).map { |e| e.code }
      expect(codes).to include(Braintree::ErrorCodes::Address::CountryCodeAlpha3IsNotAccepted)
    end

    it "returns an error if given an incorrect numeric code" do
      result = Braintree::Transaction.sale(
        :amount => "100",
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
        :billing => {
          :country_code_numeric => "FOO"
        },
      )

      expect(result.success?).to eq(false)
      codes = result.errors.for(:transaction).for(:billing).on(:country_code_numeric).map { |e| e.code }
      expect(codes).to include(Braintree::ErrorCodes::Address::CountryCodeNumericIsNotAccepted)
    end

    it "returns an error if provided product sku is invalid" do
      result = Braintree::Transaction.sale(
        :amount => "100",
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
        :product_sku => "product$ku!",
      )

      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:product_sku).map { |e| e.code }).to include(Braintree::ErrorCodes::Transaction::ProductSkuIsInvalid)
    end

    it "returns an error if provided shipping phone number is invalid" do
      result = Braintree::Transaction.sale(
        :amount => "100",
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
        :shipping => {
          :phone_number => "123-234-3456=098765"
        },
      )

      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).for(:shipping).on(:phone_number).map { |e| e.code }).to include(Braintree::ErrorCodes::Transaction::ShippingPhoneNumberIsInvalid)
    end

    it "returns an error if provided shipping method is invalid" do
      result = Braintree::Transaction.sale(
        :amount => "100",
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
        :shipping => {
          :shipping_method => "urgent"
        },
      )

      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).for(:shipping).on(:shipping_method).map { |e| e.code }).to include(Braintree::ErrorCodes::Transaction::ShippingMethodIsInvalid)
    end

    it "returns an error if provided billing phone number is invalid" do
      result = Braintree::Transaction.sale(
        :amount => "100",
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
        :billing => {
          :phone_number => "123-234-3456=098765"
        },
      )

      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).for(:billing).on(:phone_number).map { |e| e.code }).to include(Braintree::ErrorCodes::Transaction::BillingPhoneNumberIsInvalid)
    end

    context "gateway rejection reason" do
      it "exposes the cvv gateway rejection reason" do
        old_merchant = Braintree::Configuration.merchant_id
        old_public_key = Braintree::Configuration.public_key
        old_private_key = Braintree::Configuration.private_key

        begin
          Braintree::Configuration.merchant_id = "processing_rules_merchant_id"
          Braintree::Configuration.public_key = "processing_rules_public_key"
          Braintree::Configuration.private_key = "processing_rules_private_key"

          result = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "05/2009",
              :cvv => "200"
            },
          )
          expect(result.success?).to eq(false)
          expect(result.transaction.gateway_rejection_reason).to eq(Braintree::Transaction::GatewayRejectionReason::CVV)
        ensure
          Braintree::Configuration.merchant_id = old_merchant
          Braintree::Configuration.public_key = old_public_key
          Braintree::Configuration.private_key = old_private_key
        end
      end

      it "exposes the application incomplete gateway rejection reason" do
        gateway = Braintree::Gateway.new(
          :client_id => "client_id$#{Braintree::Configuration.environment}$integration_client_id",
          :client_secret => "client_secret$#{Braintree::Configuration.environment}$integration_client_secret",
          :logger => Logger.new("/dev/null"),
        )
        result = gateway.merchant.create(
          :email => "name@email.com",
          :country_code_alpha3 => "USA",
          :payment_methods => ["credit_card", "paypal"],
        )

        gateway = Braintree::Gateway.new(
          :access_token => result.credentials.access_token,
          :logger => Logger.new("/dev/null"),
        )

        result = gateway.transaction.create(
          :type => "sale",
          :amount => "4000.00",
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2020"
          },
        )
        expect(result.success?).to eq(false)
        expect(result.transaction.gateway_rejection_reason).to eq(Braintree::Transaction::GatewayRejectionReason::ApplicationIncomplete)
      end

      it "exposes the avs gateway rejection reason" do
        old_merchant = Braintree::Configuration.merchant_id
        old_public_key = Braintree::Configuration.public_key
        old_private_key = Braintree::Configuration.private_key

        begin
          Braintree::Configuration.merchant_id = "processing_rules_merchant_id"
          Braintree::Configuration.public_key = "processing_rules_public_key"
          Braintree::Configuration.private_key = "processing_rules_private_key"

          result = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :billing => {
              :street_address => "200 Fake Street"
            },
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "05/2009"
            },
          )
          expect(result.success?).to eq(false)
          expect(result.transaction.gateway_rejection_reason).to eq(Braintree::Transaction::GatewayRejectionReason::AVS)
        ensure
          Braintree::Configuration.merchant_id = old_merchant
          Braintree::Configuration.public_key = old_public_key
          Braintree::Configuration.private_key = old_private_key
        end
      end

      it "exposes the avs_and_cvv gateway rejection reason" do
        old_merchant = Braintree::Configuration.merchant_id
        old_public_key = Braintree::Configuration.public_key
        old_private_key = Braintree::Configuration.private_key

        begin
          Braintree::Configuration.merchant_id = "processing_rules_merchant_id"
          Braintree::Configuration.public_key = "processing_rules_public_key"
          Braintree::Configuration.private_key = "processing_rules_private_key"

          result = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :billing => {
              :postal_code => "20000"
            },
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "05/2009",
              :cvv => "200"
            },
          )
          expect(result.success?).to eq(false)
          expect(result.transaction.gateway_rejection_reason).to eq(Braintree::Transaction::GatewayRejectionReason::AVSAndCVV)
        ensure
          Braintree::Configuration.merchant_id = old_merchant
          Braintree::Configuration.public_key = old_public_key
          Braintree::Configuration.private_key = old_private_key
        end
      end

      it "exposes the fraud gateway rejection reason" do
        with_advanced_fraud_kount_integration_merchant do
          result = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Fraud,
              :expiration_date => "05/2017",
              :cvv => "333"
            },
          )
          expect(result.success?).to eq(false)
          expect(result.transaction.gateway_rejection_reason).to eq(Braintree::Transaction::GatewayRejectionReason::Fraud)
        end
      end

      it "exposes the risk_threshold gateway rejection reason (via test cc num)" do
        with_advanced_fraud_kount_integration_merchant do
          result = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::RiskThreshold,
              :expiration_date => "05/2017",
              :cvv => "333"
            },
          )
          expect(result.success?).to eq(false)
          expect(result.transaction.gateway_rejection_reason).to eq(Braintree::Transaction::GatewayRejectionReason::RiskThreshold)
        end
      end

      it "exposes the risk_threshold gateway rejection reason (via test test nonce)" do
        with_advanced_fraud_kount_integration_merchant do
          result = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :payment_method_nonce => Braintree::Test::Nonce::GatewayRejectedRiskThresholds,
          )
          expect(result.success?).to eq(false)
          expect(result.transaction.gateway_rejection_reason).to eq(Braintree::Transaction::GatewayRejectionReason::RiskThreshold)
        end
      end

      it "exposes the token issuance gateway rejection reason" do
        result = Braintree::Transaction.sale(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :merchant_account_id => SpecHelper::FakeVenmoAccountMerchantAccountId,
          :payment_method_nonce => Braintree::Test::Nonce::VenmoAccountTokenIssuanceError,
        )
        expect(result.success?).to eq(false)
        expect(result.transaction.gateway_rejection_reason).to eq(Braintree::Transaction::GatewayRejectionReason::TokenIssuance)
      end

      xit "exposes the excessive_retry gateway rejection reason" do
        with_duplicate_checking_merchant do
          result = nil
          counter = 0
          excessive_retry = false
          until excessive_retry || counter == 20
            result = Braintree::Transaction.sale(
              :amount => Braintree::Test::TransactionAmounts::Decline,
              :credit_card => {
                :number => Braintree::Test::CreditCardNumbers::Visa,
                :expiration_month => "05",
                :expiration_year => "2011"
              },
              )
            excessive_retry = result.transaction.status == "gateway_rejected"
            counter +=1
          end
          expect(result.transaction.gateway_rejection_reason). to eq(Braintree::Transaction::GatewayRejectionReason::ExcessiveRetry)
        end
      end
    end

    it "accepts credit card expiration month and expiration year" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_month => "05",
          :expiration_year => "2011"
        },
      )
      expect(result.success?).to eq(true)
      expect(result.transaction.credit_card_details.expiration_month).to eq("05")
      expect(result.transaction.credit_card_details.expiration_year).to eq("2011")
      expect(result.transaction.credit_card_details.expiration_date).to eq("05/2011")
    end

    it "accepts exchange_rate_quote_id" do
      result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "05/2009"
          },
          :exchange_rate_quote_id => "dummyExchangeRateQuoteId-Brainree-Ruby",
      )
      expect(result.success?).to eq(true)
      expect(result.transaction.credit_card_details.expiration_date).to eq("05/2009")
    end

    it "returns an error if provided invalid exchange_rate_quote_id" do
      result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "05/2009"
          },
          :exchange_rate_quote_id => "a" * 4010,
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:exchange_rate_quote_id)[0].code).to eq(Braintree::ErrorCodes::Transaction::ExchangeRateQuoteIdTooLong)
    end

    it "returns some error if customer_id is invalid" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :customer_id => 123456789,
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:customer_id)[0].code).to eq("91510")
      expect(result.message).to eq("Customer ID is invalid.")
    end

    it "can create custom fields" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
        :custom_fields => {
          :store_me => "custom value"
        },
      )
      expect(result.success?).to eq(true)
      expect(result.transaction.custom_fields).to eq({:store_me => "custom value"})
    end

    it "returns nil if a custom field is not defined" do
      create_result = Braintree::Transaction.sale(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "12/2012"
        },
        :custom_fields => {
          :store_me => ""
        },
      )

      result = Braintree::Transaction.find(create_result.transaction.id)

      expect(result.custom_fields).to eq({})
    end

    it "returns an error if custom_field is not registered" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
        :custom_fields => {
          :invalid_key => "custom value"
        },
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:custom_fields)[0].message).to eq("Custom field is invalid: invalid_key.")
    end

    it "returns the given params if validations fail" do
      params = {
        :transaction => {
          :type => "sale",
          :amount => nil,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        }
      }
      result = Braintree::Transaction.create(params[:transaction])
      expect(result.success?).to eq(false)
      expect(result.params).to eq({:transaction => {:type => "sale", :amount => nil, :credit_card => {:expiration_date => "05/2009"}}})
    end

    it "returns errors if validations fail (tests many errors at once for spec speed)" do
      params = {
        :transaction => {
          :type => "pants",
          :amount => nil,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
          :customer_id => "invalid",
          :order_id => "too long" * 250,
          :channel => "too long" * 250,
          :payment_method_token => "too long and doesn't belong to customer" * 250
        }
      }
      result = Braintree::Transaction.create(params[:transaction])
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:base).map { |error| error.code }).to include(Braintree::ErrorCodes::Transaction::PaymentMethodDoesNotBelongToCustomer)
      expect(result.errors.for(:transaction).on(:customer_id)[0].code).to eq(Braintree::ErrorCodes::Transaction::CustomerIdIsInvalid)
      expect(result.errors.for(:transaction).on(:payment_method_token)[0].code).to eq(Braintree::ErrorCodes::Transaction::PaymentMethodTokenIsInvalid)
      expect(result.errors.for(:transaction).on(:type)[0].code).to eq(Braintree::ErrorCodes::Transaction::TypeIsInvalid)
    end

    it "returns an error if amount is negative" do
      params = {
        :transaction => {
          :type => "credit",
          :amount => "-1"
        }
      }
      result = Braintree::Transaction.create(params[:transaction])
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:amount)[0].code).to eq(Braintree::ErrorCodes::Transaction::AmountCannotBeNegative)
    end

    it "returns an error if amount is not supported by processor" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :merchant_account_id => SpecHelper::HiperBRLMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Hiper,
          :expiration_date => "05/2009"
        },
        :amount => "0.20",
        :options => {
          :credit_card => {
            :account_type => "credit",
          }
        },
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:amount)[0].code).to eq(Braintree::ErrorCodes::Transaction::AmountNotSupportedByProcessor)
    end

    it "returns an error if amount is invalid format" do
      params = {
        :transaction => {
          :type => "sale",
          :amount => "shorts"
        }
      }
      result = Braintree::Transaction.create(params[:transaction])
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:amount)[0].code).to eq(Braintree::ErrorCodes::Transaction::AmountIsInvalid)
    end

    it "returns an error if type is not given" do
      params = {
        :transaction => {
          :type => nil
        }
      }
      result = Braintree::Transaction.create(params[:transaction])
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:type)[0].code).to eq(Braintree::ErrorCodes::Transaction::TypeIsRequired)
    end

    it "returns an error if no credit card is given" do
      params = {
        :transaction => {}
      }
      result = Braintree::Transaction.create(params[:transaction])
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:base)[0].code).to eq(Braintree::ErrorCodes::Transaction::CreditCardIsRequired)
    end

    it "returns an error if the given payment method token doesn't belong to the customer" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        },
      )
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :customer_id => customer.id,
        :payment_method_token => customer.credit_cards[0].token + "x",
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:base)[0].code).to eq(Braintree::ErrorCodes::Transaction::PaymentMethodDoesNotBelongToCustomer)
    end

    context "new credit card for existing customer" do
      it "allows a new credit card to be used for an existing customer" do
        customer = Braintree::Customer.create!(
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2010"
          },
        )
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :customer_id => customer.id,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12"
          },
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.credit_card_details.masked_number).to eq("401288******1881")
        expect(result.transaction.vault_credit_card).to be_nil
      end

      it "allows a new credit card to be used and stored in the vault" do
        customer = Braintree::Customer.create!(
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2010"
          },
        )
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :customer_id => customer.id,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :options => {:store_in_vault => true},
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.credit_card_details.masked_number).to eq("401288******1881")
        expect(result.transaction.vault_credit_card.masked_number).to eq("401288******1881")
        expect(result.transaction.credit_card_details.unique_number_identifier).not_to be_nil
      end
    end

    it "snapshots plan, add_ons and discounts from subscription" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        },
      )

      result = Braintree::Subscription.create(
        :payment_method_token => customer.credit_cards.first.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :add_ons => {
          :add => [
            {
              :amount => BigDecimal("11.00"),
              :inherited_from_id => SpecHelper::AddOnIncrease10,
              :quantity => 2,
              :number_of_billing_cycles => 5
            },
            {
              :amount => BigDecimal("21.00"),
              :inherited_from_id => SpecHelper::AddOnIncrease20,
              :quantity => 3,
              :number_of_billing_cycles => 6
            }
          ]
        },
        :discounts => {
          :add => [
            {
              :amount => BigDecimal("7.50"),
              :inherited_from_id => SpecHelper::Discount7,
              :quantity => 2,
              :never_expires => true
            }
          ]
        },
      )

      expect(result.success?).to be(true)
      transaction = result.subscription.transactions.first

      expect(transaction.plan_id).to eq(SpecHelper::TriallessPlan[:id])

      expect(transaction.add_ons.size).to eq(2)
      add_ons = transaction.add_ons.sort_by { |add_on| add_on.id }

      expect(add_ons.first.id).to eq("increase_10")
      expect(add_ons.first.amount).to eq(BigDecimal("11.00"))
      expect(add_ons.first.quantity).to eq(2)
      expect(add_ons.first.number_of_billing_cycles).to eq(5)
      expect(add_ons.first.never_expires?).to be(false)

      expect(add_ons.last.id).to eq("increase_20")
      expect(add_ons.last.amount).to eq(BigDecimal("21.00"))
      expect(add_ons.last.quantity).to eq(3)
      expect(add_ons.last.number_of_billing_cycles).to eq(6)
      expect(add_ons.last.never_expires?).to be(false)

      expect(transaction.discounts.size).to eq(1)

      expect(transaction.discounts.first.id).to eq("discount_7")
      expect(transaction.discounts.first.amount).to eq(BigDecimal("7.50"))
      expect(transaction.discounts.first.quantity).to eq(2)
      expect(transaction.discounts.first.number_of_billing_cycles).to be_nil
      expect(transaction.discounts.first.never_expires?).to be(true)
    end

    context "descriptors" do
      it "accepts name and phone" do
        result = Braintree::Transaction.sale(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
          :descriptor => {
            :name => "123*123456789012345678",
            :phone => "3334445555",
            :url => "ebay.com"
          },
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.descriptor.name).to eq("123*123456789012345678")
        expect(result.transaction.descriptor.phone).to eq("3334445555")
        expect(result.transaction.descriptor.url).to eq("ebay.com")
      end

      it "has validation errors if format is invalid" do
        result = Braintree::Transaction.sale(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
          :descriptor => {
            :name => "badcompanyname12*badproduct12",
            :phone => "%bad4445555",
            :url => "12345678901234"
          },
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:descriptor).on(:name)[0].code).to eq(Braintree::ErrorCodes::Descriptor::NameFormatIsInvalid)
        expect(result.errors.for(:transaction).for(:descriptor).on(:phone)[0].code).to eq(Braintree::ErrorCodes::Descriptor::PhoneFormatIsInvalid)
        expect(result.errors.for(:transaction).for(:descriptor).on(:url)[0].code).to eq(Braintree::ErrorCodes::Descriptor::UrlFormatIsInvalid)
      end
    end

    context "level 2 fields" do
      it "accepts tax_amount, tax_exempt, and purchase_order_number" do
        result = Braintree::Transaction.sale(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
          :tax_amount => "0.05",
          :tax_exempt => false,
          :purchase_order_number => "12345678901234567",
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.tax_amount).to eq(BigDecimal("0.05"))
        expect(result.transaction.tax_exempt).to eq(false)
        expect(result.transaction.purchase_order_number).to eq("12345678901234567")
      end

      it "accepts tax_amount as a BigDecimal" do
        result = Braintree::Transaction.sale(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
          :tax_amount => BigDecimal("1.99"),
          :tax_exempt => true,
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.tax_amount).to eq(BigDecimal("1.99"))
        expect(result.transaction.tax_exempt).to eq(true)
        expect(result.transaction.purchase_order_number).to be_nil
      end

      context "validations" do
        it "tax_amount" do
          result = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "05/2009"
            },
            :tax_amount => "abcd",
          )
          expect(result.success?).to eq(false)
          expect(result.errors.for(:transaction).on(:tax_amount)[0].code).to eq(Braintree::ErrorCodes::Transaction::TaxAmountFormatIsInvalid)
        end

        it "purchase_order_number length" do
          result = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "05/2009"
            },
            :purchase_order_number => "a" * 18,
          )
          expect(result.success?).to eq(false)
          expect(result.errors.for(:transaction).on(:purchase_order_number)[0].code).to eq(Braintree::ErrorCodes::Transaction::PurchaseOrderNumberIsTooLong)
        end

        it "purchase_order_number format" do
          result = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "05/2009"
            },
            :purchase_order_number => "\303\237\303\245\342\210\202",
          )
          expect(result.success?).to eq(false)
          expect(result.errors.for(:transaction).on(:purchase_order_number)[0].code).to eq(Braintree::ErrorCodes::Transaction::PurchaseOrderNumberIsInvalid)
        end
      end
    end

    context "transaction_source" do
      it "marks a transactions as recurring_first" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :transaction_source => "recurring_first",
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.recurring).to eq(true)
      end

      it "marks a transactions as recurring" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :transaction_source => "recurring",
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.recurring).to eq(true)
      end

      it "successfully creates a transaction with installment_first" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :transaction_source => "installment_first",
        )
        expect(result.success?).to eq(true)
      end

      it "successfully creates a transaction with installment" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :transaction_source => "installment",
        )
        expect(result.success?).to eq(true)
      end

      it "marks a transactions as merchant" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :transaction_source => "merchant",
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.recurring).to eq(false)
      end

      it "marks a transactions as moto" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :transaction_source => "moto",
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.recurring).to eq(false)
      end

      it "marks a transactions as pre_auth" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/26",
          },
          :transaction_source => "estimated",
        )
        expect(result.success?).to eq(true)
      end

      it "handles validation when transaction source invalid" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :transaction_source => "invalid_value",
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).on(:transaction_source)[0].code).to eq(Braintree::ErrorCodes::Transaction::TransactionSourceIsInvalid)
      end
    end

    context "store_in_vault_on_success" do
      context "passed as true" do
        it "stores vault records when transaction succeeds" do
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :customer => {
              :last_name => "Doe"
            },
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "12/12",
            },
            :options => {:store_in_vault_on_success => true},
          )
          expect(result.success?).to eq(true)
          expect(result.transaction.vault_customer.last_name).to eq("Doe")
          expect(result.transaction.vault_credit_card.masked_number).to eq("401288******1881")
          expect(result.transaction.credit_card_details.unique_number_identifier).not_to be_nil
        end

        it "does not store vault records when true and transaction fails" do
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Decline,
            :customer => {
              :last_name => "Doe"
            },
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "12/12",
            },
            :options => {:store_in_vault_on_success => true},
          )
          expect(result.success?).to eq(false)
          expect(result.transaction.vault_customer).to be_nil
          expect(result.transaction.vault_credit_card).to be_nil
        end
      end

      context "passed as false" do
        it "does not store vault records when transaction succeeds" do
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :customer => {
              :last_name => "Doe"
            },
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "12/12",
            },
            :options => {:store_in_vault_on_success => false},
          )
          expect(result.success?).to eq(true)
          expect(result.transaction.vault_customer).to be_nil
          expect(result.transaction.vault_credit_card).to be_nil
        end

        it "does not store vault records when transaction fails" do
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Decline,
            :customer => {
              :last_name => "Doe"
            },
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "12/12",
            },
            :options => {:store_in_vault_on_success => false},
          )
          expect(result.success?).to eq(false)
          expect(result.transaction.vault_customer).to be_nil
          expect(result.transaction.vault_credit_card).to be_nil
        end
      end
    end

    context "processing_overrides" do
      it "creates a successful transaction with options processing_overrides" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :customer => {
            :last_name => "Doe"
          },
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :options => {
            :processing_overrides => {
              :customer_email => "RubySDK@example.com",
              :customer_first_name => "RubySDK_test_customer_first_name",
              :customer_last_name => "RubySDK_test customer_last_name",
              :customer_tax_identifier => "1.2.3.4.5.6"
            },
          },
        )
        expect(result.success?).to eq(true)
      end
    end

    context "service fees" do
      it "allows specifying service fees" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :merchant_account_id => SpecHelper::NonDefaultSubMerchantAccountId,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :service_fee_amount => "1.00",
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.service_fee_amount).to eq(BigDecimal("1.00"))
      end

      it "raises an error if transaction merchant account is a master" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :service_fee_amount => "1.00",
        )
        expect(result.success?).to eq(false)
        expected_error_code = Braintree::ErrorCodes::Transaction::ServiceFeeAmountNotAllowedOnMasterMerchantAccount
        expect(result.errors.for(:transaction).on(:service_fee_amount)[0].code).to eq(expected_error_code)
      end

      it "raises an error if no service fee is present on a sub merchant account transaction" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :merchant_account_id => SpecHelper::NonDefaultSubMerchantAccountId,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
        )
        expect(result.success?).to eq(false)
        expected_error_code = Braintree::ErrorCodes::Transaction::SubMerchantAccountRequiresServiceFeeAmount
        expect(result.errors.for(:transaction).on(:merchant_account_id)[0].code).to eq(expected_error_code)
      end

      it "raises an error if service fee amount is negative" do
        result = Braintree::Transaction.create(
          :merchant_account_id => SpecHelper::NonDefaultSubMerchantAccountId,
          :service_fee_amount => "-1.00",
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).on(:service_fee_amount)[0].code).to eq(Braintree::ErrorCodes::Transaction::ServiceFeeAmountCannotBeNegative)
      end

      it "raises an error if service fee amount is invalid" do
        result = Braintree::Transaction.create(
          :merchant_account_id => SpecHelper::NonDefaultSubMerchantAccountId,
          :service_fee_amount => "invalid amount",
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).on(:service_fee_amount)[0].code).to eq(Braintree::ErrorCodes::Transaction::ServiceFeeAmountFormatIsInvalid)
      end
    end

    context "escrow" do
      it "allows specifying transactions to be held for escrow" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :merchant_account_id => SpecHelper::NonDefaultSubMerchantAccountId,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :service_fee_amount => "10.00",
          :options => {:hold_in_escrow => true},
        )

        expect(result.success?).to eq(true)
        expect(result.transaction.escrow_status).to eq(Braintree::Transaction::EscrowStatus::HoldPending)
      end

      it "raises an error if transaction merchant account is a master" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :service_fee_amount => "1.00",
          :options => {:hold_in_escrow => true},
        )
        expect(result.success?).to eq(false)
        expected_error_code = Braintree::ErrorCodes::Transaction::CannotHoldInEscrow
        expect(result.errors.for(:transaction).on(:base)[0].code).to eq(expected_error_code)
      end
    end

    context "client API" do
      it "can create a transaction with a shared card nonce" do
        nonce = nonce_for_new_payment_method(
          :credit_card => {
            :number => "4111111111111111",
            :expiration_month => "11",
            :expiration_year => "2099",
          },
          :share => true,
        )
        expect(nonce).not_to be_nil

        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => nonce,
        )
        expect(result.success?).to eq(true)
      end

      it "can create a transaction with a vaulted card nonce" do
        customer = Braintree::Customer.create!
        nonce = nonce_for_new_payment_method(
          :credit_card => {
            :number => "4111111111111111",
            :expiration_month => "11",
            :expiration_year => "2099",
          },
          :client_token_options => {
            :customer_id => customer.id,
          },
        )
        expect(nonce).not_to be_nil

        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => nonce,
        )
        expect(result.success?).to eq(true)
      end

      it "can create a transaction with a vaulted PayPal account" do
        customer = Braintree::Customer.create!
        nonce = nonce_for_new_payment_method(
          :paypal_account => {
            :consent_code => "PAYPAL_CONSENT_CODE",
          },
          :client_token_options => {
            :customer_id => customer.id,
          },
        )
        expect(nonce).not_to be_nil

        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => nonce,
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.paypal_details).not_to be_nil
        expect(result.transaction.paypal_details.debug_id).not_to be_nil
      end

      it "can create a transaction with a params nonce with PayPal account params" do
        nonce = nonce_for_new_payment_method(
          :paypal_account => {
            :consent_code => "PAYPAL_CONSENT_CODE",
          },
        )
        expect(nonce).not_to be_nil

        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => nonce,
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.paypal_details).not_to be_nil
        expect(result.transaction.paypal_details.debug_id).not_to be_nil
      end

      it "can create a transaction with a fake meta checkout card nonce" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => Braintree::Test::Nonce::MetaCheckoutCard,
        )

        result.success?.should == true
        result.transaction.should_not be_nil
        meta_checkout_card_details = result.transaction.meta_checkout_card_details
        meta_checkout_card_details.should_not be_nil
        meta_checkout_card_details.bin.should == "401288"
        meta_checkout_card_details.card_type.should == Braintree::CreditCard::CardType::Visa
        meta_checkout_card_details.cardholder_name.should == "Meta Checkout Card Cardholder"
        meta_checkout_card_details.container_id.should == "container123"
        meta_checkout_card_details.customer_location.should == "US"
        next_year = Date.today().next_year().year.to_s
        meta_checkout_card_details.expiration_date.should == "12/".concat(next_year)
        meta_checkout_card_details.expiration_year.should == next_year
        meta_checkout_card_details.expiration_month.should == "12"
        meta_checkout_card_details.image_url.should == "https://assets.braintreegateway.com/payment_method_logo/visa.png?environment=development"
        meta_checkout_card_details.is_network_tokenized.should == false
        meta_checkout_card_details.last_4.should == "1881"
        meta_checkout_card_details.masked_number.should == "401288******1881"
        meta_checkout_card_details.prepaid.should == "No"
      end

      it "can create a transaction with a fake meta checkout token nonce" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => Braintree::Test::Nonce::MetaCheckoutToken,
        )

        result.success?.should == true
        result.transaction.should_not be_nil
        meta_checkout_token_details = result.transaction.meta_checkout_token_details

        meta_checkout_token_details.should_not be_nil
        meta_checkout_token_details.bin.should == "401288"
        meta_checkout_token_details.card_type.should == Braintree::CreditCard::CardType::Visa
        meta_checkout_token_details.cardholder_name.should == "Meta Checkout Token Cardholder"
        meta_checkout_token_details.container_id.should == "container123"
        meta_checkout_token_details.cryptogram.should == "AlhlvxmN2ZKuAAESNFZ4GoABFA=="
        meta_checkout_token_details.customer_location.should == "US"
        meta_checkout_token_details.ecommerce_indicator.should == "07"
        next_year = Date.today().next_year().year.to_s
        meta_checkout_token_details.expiration_date.should == "12/".concat(next_year)
        meta_checkout_token_details.expiration_year.should == next_year
        meta_checkout_token_details.expiration_month.should == "12"
        meta_checkout_token_details.image_url.should == "https://assets.braintreegateway.com/payment_method_logo/visa.png?environment=development"
        meta_checkout_token_details.is_network_tokenized.should == true
        meta_checkout_token_details.last_4.should == "1881"
        meta_checkout_token_details.masked_number.should == "401288******1881"
        meta_checkout_token_details.prepaid.should == "No"
      end

      it "can create a transaction with a fake apple pay nonce" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => Braintree::Test::Nonce::ApplePayVisa,
        )
        expect(result.success?).to eq(true)
        expect(result.transaction).not_to be_nil
        apple_pay_details = result.transaction.apple_pay_details
        expect(apple_pay_details).not_to be_nil
        expect(apple_pay_details.bin).not_to be_nil
        expect(apple_pay_details.card_type).to eq(Braintree::ApplePayCard::CardType::Visa)
        expect(apple_pay_details.payment_instrument_name).to eq("Visa 8886")
        expect(apple_pay_details.source_description).to eq("Visa 8886")
        expect(apple_pay_details.expiration_month.to_i).to be > 0
        expect(apple_pay_details.expiration_year.to_i).to be > 0
        expect(apple_pay_details.cardholder_name).not_to be_nil
        expect(apple_pay_details.image_url).not_to be_nil
        expect(apple_pay_details.token).to be_nil
        expect(apple_pay_details.prepaid).not_to be_nil
        expect(apple_pay_details.healthcare).not_to be_nil
        expect(apple_pay_details.debit).not_to be_nil
        expect(apple_pay_details.durbin_regulated).not_to be_nil
        expect(apple_pay_details.commercial).not_to be_nil
        expect(apple_pay_details.payroll).not_to be_nil
        expect(apple_pay_details.product_id).not_to be_nil
      end

      it "can create a vaulted transaction with a fake apple pay nonce" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => Braintree::Test::Nonce::ApplePayVisa,
          :options => {:store_in_vault_on_success => true},
        )
        expect(result.success?).to eq(true)
        expect(result.transaction).not_to be_nil
        apple_pay_details = result.transaction.apple_pay_details
        expect(apple_pay_details).not_to be_nil
        expect(apple_pay_details.card_type).to eq(Braintree::ApplePayCard::CardType::Visa)
        expect(apple_pay_details.payment_instrument_name).to eq("Visa 8886")
        expect(apple_pay_details.source_description).to eq("Visa 8886")
        expect(apple_pay_details.expiration_month.to_i).to be > 0
        expect(apple_pay_details.expiration_year.to_i).to be > 0
        expect(apple_pay_details.cardholder_name).not_to be_nil
        expect(apple_pay_details.image_url).not_to be_nil
        expect(apple_pay_details.token).not_to be_nil
      end

      it "can create a transaction with a fake google pay proxy card nonce" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => Braintree::Test::Nonce::GooglePayDiscover,
        )
        expect(result.success?).to eq(true)
        expect(result.transaction).not_to be_nil
        google_pay_details = result.transaction.google_pay_details
        expect(google_pay_details).not_to be_nil
        expect(google_pay_details.bin).not_to be_nil
        expect(google_pay_details.card_type).to eq(Braintree::CreditCard::CardType::Discover)
        expect(google_pay_details.virtual_card_type).to eq(Braintree::CreditCard::CardType::Discover)
        expect(google_pay_details.last_4).to eq("1117")
        expect(google_pay_details.virtual_card_last_4).to eq("1117")
        expect(google_pay_details.source_description).to eq("Discover 1111")
        expect(google_pay_details.expiration_month.to_i).to be > 0
        expect(google_pay_details.expiration_year.to_i).to be > 0
        expect(google_pay_details.google_transaction_id).to eq("google_transaction_id")
        expect(google_pay_details.image_url).not_to be_nil
        expect(google_pay_details.is_network_tokenized?).to eq(false)
        expect(google_pay_details.token).to be_nil
        expect(google_pay_details.prepaid).not_to be_nil
        expect(google_pay_details.healthcare).not_to be_nil
        expect(google_pay_details.debit).not_to be_nil
        expect(google_pay_details.durbin_regulated).not_to be_nil
        expect(google_pay_details.commercial).not_to be_nil
        expect(google_pay_details.payroll).not_to be_nil
        expect(google_pay_details.product_id).not_to be_nil
      end

      it "can create a vaulted transaction with a fake google pay proxy card nonce" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => Braintree::Test::Nonce::GooglePayDiscover,
          :options => {:store_in_vault_on_success => true},
        )
        expect(result.success?).to eq(true)
        expect(result.transaction).not_to be_nil
        google_pay_details = result.transaction.google_pay_details
        expect(google_pay_details).not_to be_nil
        expect(google_pay_details.card_type).to eq(Braintree::CreditCard::CardType::Discover)
        expect(google_pay_details.virtual_card_type).to eq(Braintree::CreditCard::CardType::Discover)
        expect(google_pay_details.last_4).to eq("1117")
        expect(google_pay_details.virtual_card_last_4).to eq("1117")
        expect(google_pay_details.source_description).to eq("Discover 1111")
        expect(google_pay_details.expiration_month.to_i).to be > 0
        expect(google_pay_details.expiration_year.to_i).to be > 0
        expect(google_pay_details.google_transaction_id).to eq("google_transaction_id")
        expect(google_pay_details.image_url).not_to be_nil
        expect(google_pay_details.is_network_tokenized?).to eq(false)
        expect(google_pay_details.token).not_to be_nil
      end

      it "can create a transaction with a fake google pay network token nonce" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => Braintree::Test::Nonce::GooglePayMasterCard,
        )
        expect(result.success?).to eq(true)
        expect(result.transaction).not_to be_nil
        google_pay_details = result.transaction.google_pay_details
        expect(google_pay_details).not_to be_nil
        expect(google_pay_details.card_type).to eq(Braintree::CreditCard::CardType::MasterCard)
        expect(google_pay_details.virtual_card_type).to eq(Braintree::CreditCard::CardType::MasterCard)
        expect(google_pay_details.last_4).to eq("4444")
        expect(google_pay_details.virtual_card_last_4).to eq("4444")
        expect(google_pay_details.source_description).to eq("MasterCard 4444")
        expect(google_pay_details.expiration_month.to_i).to be > 0
        expect(google_pay_details.expiration_year.to_i).to be > 0
        expect(google_pay_details.google_transaction_id).to eq("google_transaction_id")
        expect(google_pay_details.is_network_tokenized?).to eq(true)
      end

      it "can create a transaction with a fake venmo account nonce" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :merchant_account_id => SpecHelper::FakeVenmoAccountMerchantAccountId,
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => Braintree::Test::Nonce::VenmoAccount,
          :options => {:store_in_vault => true},
        )
        expect(result).to be_success

        expect(result.transaction.payment_instrument_type).to eq(Braintree::PaymentInstrumentType::VenmoAccount)
        venmo_account_details = result.transaction.venmo_account_details
        expect(venmo_account_details).to be_a(Braintree::Transaction::VenmoAccountDetails)
        expect(venmo_account_details.token).to respond_to(:to_str)
        expect(venmo_account_details.username).to eq("venmojoe")
        expect(venmo_account_details.venmo_user_id).to eq("1234567891234567891")
        expect(venmo_account_details.image_url).to include(".png")
        expect(venmo_account_details.source_description).to eq("Venmo Account: venmojoe")
      end

      it "can create a transaction with a fake venmo account nonce specifying a profile" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :merchant_account_id => SpecHelper::FakeVenmoAccountMerchantAccountId,
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => Braintree::Test::Nonce::VenmoAccount,
          :options => {:store_in_vault => true, :venmo => {:profile_id => "integration_venmo_merchant_public_id"}},
        )
        expect(result).to be_success
      end

      it "can create a transaction with an unknown nonce" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => Braintree::Test::Nonce::AbstractTransactable,
        )
        expect(result.success?).to eq(true)
        expect(result.transaction).not_to be_nil
      end

      it "can create a transaction with local payment webhook content" do
        result = Braintree::Transaction.sale(
          :amount => "100",
          :options => {
            :submit_for_settlement => true
          },
          :paypal_account => {
            :payer_id => "PAYER-1234",
            :payment_id => "PAY-5678",
          },
        )

        expect(result.success?).to eq(true)
        expect(result.transaction.status).to eq(Braintree::Transaction::Status::Settling)
        expect(result.transaction.paypal_details.payer_id).to eq("PAYER-1234")
        expect(result.transaction.paypal_details.payment_id).to eq("PAY-5678")
      end

      it "can create a transaction with a payee id" do
        nonce = nonce_for_new_payment_method(
          :paypal_account => {
            :consent_code => "PAYPAL_CONSENT_CODE",
          },
        )
        expect(nonce).not_to be_nil

        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => nonce,
          :paypal_account => {
            :payee_id => "fake-payee-id"
          },
        )

        expect(result.success?).to eq(true)
        expect(result.transaction.paypal_details).not_to be_nil
        expect(result.transaction.paypal_details.debug_id).not_to be_nil
        expect(result.transaction.paypal_details.payee_id).to eq("fake-payee-id")
      end

      it "can create a transaction with a payee id in the options params" do
        nonce = nonce_for_new_payment_method(
          :paypal_account => {
            :consent_code => "PAYPAL_CONSENT_CODE",
          },
        )
        expect(nonce).not_to be_nil

        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => nonce,
          :paypal_account => {},
          :options => {
            :payee_id => "fake-payee-id"
          },
        )

        expect(result.success?).to eq(true)
        expect(result.transaction.paypal_details).not_to be_nil
        expect(result.transaction.paypal_details.debug_id).not_to be_nil
        expect(result.transaction.paypal_details.payee_id).to eq("fake-payee-id")
      end

      it "can create a transaction with a payee id in options.paypal" do
        nonce = nonce_for_new_payment_method(
          :paypal_account => {
            :consent_code => "PAYPAL_CONSENT_CODE",
          },
        )
        expect(nonce).not_to be_nil

        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => nonce,
          :options => {
            :paypal => {
              :payee_id => "fake-payee-id"
            }
          },
        )

        expect(result.success?).to eq(true)
        expect(result.transaction.paypal_details).not_to be_nil
        expect(result.transaction.paypal_details.debug_id).not_to be_nil
        expect(result.transaction.paypal_details.payee_id).to eq("fake-payee-id")
      end

      it "can create a transaction with a payee email" do
        nonce = nonce_for_new_payment_method(
          :paypal_account => {
            :consent_code => "PAYPAL_CONSENT_CODE",
          },
        )
        expect(nonce).not_to be_nil

        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => nonce,
          :paypal_account => {
            :payee_email => "bt_seller_us@paypal.com"
          },
        )

        expect(result.success?).to eq(true)
        expect(result.transaction.paypal_details).not_to be_nil
        expect(result.transaction.paypal_details.debug_id).not_to be_nil
        expect(result.transaction.paypal_details.payee_email).to eq("bt_seller_us@paypal.com")
      end

      it "can create a transaction with a payee email in the options params" do
        nonce = nonce_for_new_payment_method(
          :paypal_account => {
            :consent_code => "PAYPAL_CONSENT_CODE",
          },
        )
        expect(nonce).not_to be_nil

        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => nonce,
          :paypal_account => {},
          :options => {
            :payee_email => "bt_seller_us@paypal.com"
          },
        )

        expect(result.success?).to eq(true)
        expect(result.transaction.paypal_details).not_to be_nil
        expect(result.transaction.paypal_details.debug_id).not_to be_nil
        expect(result.transaction.paypal_details.payee_email).to eq("bt_seller_us@paypal.com")
      end

      it "can create a transaction with a payee email in options.paypal" do
        nonce = nonce_for_new_payment_method(
          :paypal_account => {
            :consent_code => "PAYPAL_CONSENT_CODE",
          },
        )
        expect(nonce).not_to be_nil

        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => nonce,
          :options => {
            :paypal => {
              :payee_email => "bt_seller_us@paypal.com"
            }
          },
        )

        expect(result.success?).to eq(true)
        expect(result.transaction.paypal_details).not_to be_nil
        expect(result.transaction.paypal_details.debug_id).not_to be_nil
        expect(result.transaction.paypal_details.payee_email).to eq("bt_seller_us@paypal.com")
      end

      it "can create a transaction with a paypal custom field" do
        nonce = nonce_for_new_payment_method(
          :paypal_account => {
            :consent_code => "PAYPAL_CONSENT_CODE",
          },
        )
        expect(nonce).not_to be_nil

        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => nonce,
          :options => {
            :paypal => {
              :custom_field => "Additional info"
            }
          },
        )

        expect(result.success?).to eq(true)
        expect(result.transaction.paypal_details).not_to be_nil
        expect(result.transaction.paypal_details.debug_id).not_to be_nil
        expect(result.transaction.paypal_details.custom_field).to eq("Additional info")
      end

      it "can create a transaction with a paypal description" do
        nonce = nonce_for_new_payment_method(
          :paypal_account => {
            :consent_code => "PAYPAL_CONSENT_CODE",
          },
        )
        expect(nonce).not_to be_nil

        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => nonce,
          :options => {
            :paypal => {
              :description => "A great product"
            }
          },
        )

        expect(result.success?).to eq(true)
        expect(result.transaction.paypal_details).not_to be_nil
        expect(result.transaction.paypal_details.debug_id).not_to be_nil
        expect(result.transaction.paypal_details.description).to eq("A great product")
      end

      it "can create a transaction with STC supplementary data" do
        nonce = nonce_for_new_payment_method(
          :paypal_account => {
            :consent_code => "PAYPAL_CONSENT_CODE",
          },
        )
        expect(nonce).not_to be_nil

        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => nonce,
          :options => {
            :paypal => {
              :supplementary_data => {
                :key1 => "value1",
                :key2 => "value2",
              }
            }
          },
        )

        # note - supplementary data is not returned in response
        expect(result.success?).to eq(true)
      end
    end

    context "three_d_secure" do
      # NEXT_MAJOR_VERSION Remove this test. :three_d_secure_token is deprecated in favor of :three_d_secure_authentication_id
      it "can create a transaction with a three_d_secure token" do
        three_d_secure_token = SpecHelper.create_3ds_verification(
          SpecHelper::ThreeDSecureMerchantAccountId,
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_month => "12",
          :expiration_year => "2012",
        )

        result = Braintree::Transaction.create(
          :type => "sale",
          :merchant_account_id => SpecHelper::ThreeDSecureMerchantAccountId,
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :three_d_secure_token => three_d_secure_token,
        )

        expect(result.success?).to eq(true)
      end

      it "gateway rejects transactions if 3DS is required but not provided" do
        nonce = nonce_for_new_payment_method(
          :credit_card => {
            :number => "4111111111111111",
            :expiration_month => "11",
            :expiration_year => "2099",
          },
        )
        expect(nonce).not_to be_nil
        result = Braintree::Transaction.create(
          :merchant_account_id => SpecHelper::ThreeDSecureMerchantAccountId,
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => nonce,
          :options => {
            :three_d_secure => {
              :required => true,
            }
          },
        )

        expect(result.success?).to eq(false)
        expect(result.transaction.gateway_rejection_reason).to eq(Braintree::Transaction::GatewayRejectionReason::ThreeDSecure)
      end


      it "can create a transaction without a three_d_secure_authentication_id" do
        result = Braintree::Transaction.create(
          :merchant_account_id => SpecHelper::ThreeDSecureMerchantAccountId,
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
        )
        expect(result.success?).to eq(true)
      end

      context "with three_d_secure_authentication_id" do
        it "can create a transaction with a three_d_secure_authentication_id" do
          three_d_secure_authentication_id = SpecHelper.create_3ds_verification(
            SpecHelper::ThreeDSecureMerchantAccountId,
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_month => "12",
            :expiration_year => "2022",
          )

          result = Braintree::Transaction.create(
            :merchant_account_id => SpecHelper::ThreeDSecureMerchantAccountId,
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "12/22",
            },
            :three_d_secure_authentication_id => three_d_secure_authentication_id,
          )

          expect(result.success?).to eq(true)
        end
        it "returns an error if sent a nil three_d_secure_authentication_id" do
          result = Braintree::Transaction.create(
            :merchant_account_id => SpecHelper::ThreeDSecureMerchantAccountId,
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "12/12",
            },
            :three_d_secure_authentication_id => nil,
          )
          expect(result.success?).to eq(false)
          expect(result.errors.for(:transaction).on(:three_d_secure_authentication_id)[0].code).to eq(Braintree::ErrorCodes::Transaction::ThreeDSecureAuthenticationIdIsInvalid)
        end
        it "returns an error if merchant_account in the payment_method does not match with 3ds data" do
          three_d_secure_authentication_id = SpecHelper.create_3ds_verification(
            SpecHelper::ThreeDSecureMerchantAccountId,
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_month => "12",
            :expiration_year => "2012",
          )

          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::MasterCard,
              :expiration_date => "12/12",
            },
            :three_d_secure_authentication_id => three_d_secure_authentication_id,
          )
          expect(result.success?).to eq(false)
          expect(result.errors.for(:transaction).on(:three_d_secure_authentication_id)[0].code).to eq(Braintree::ErrorCodes::Transaction::ThreeDSecureTransactionPaymentMethodDoesntMatchThreeDSecureAuthenticationPaymentMethod)
        end
        it "returns an error if 3ds lookup data does not match txn data" do
          three_d_secure_authentication_id = SpecHelper.create_3ds_verification(
            SpecHelper::ThreeDSecureMerchantAccountId,
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_month => "12",
            :expiration_year => "2012",
          )

          result = Braintree::Transaction.create(
            :merchant_account_id => SpecHelper::ThreeDSecureMerchantAccountId,
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::MasterCard,
              :expiration_date => "12/12",
            },
            :three_d_secure_authentication_id => three_d_secure_authentication_id,
          )
          expect(result.success?).to eq(false)
          expect(result.errors.for(:transaction).on(:three_d_secure_authentication_id)[0].code).to eq(Braintree::ErrorCodes::Transaction::ThreeDSecureTransactionPaymentMethodDoesntMatchThreeDSecureAuthenticationPaymentMethod)
        end
        it "returns an error if three_d_secure_authentication_id is supplied with three_d_secure_pass_thru" do
          three_d_secure_authentication_id = SpecHelper.create_3ds_verification(
            SpecHelper::ThreeDSecureMerchantAccountId,
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_month => "12",
            :expiration_year => "2012",
          )
          result = Braintree::Transaction.create(
            :merchant_account_id => SpecHelper::ThreeDSecureMerchantAccountId,
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "12/12",
            },
            :three_d_secure_authentication_id => three_d_secure_authentication_id,
            :three_d_secure_pass_thru => {
              :eci_flag => "05",
              :cavv => "some_cavv",
              :xid => "some_xid",
              :three_d_secure_version => "1.0.2",
              :authentication_response => "Y",
              :directory_response => "Y",
              :cavv_algorithm => "2",
              :ds_transaction_id => "some_ds_id",
            },
          )
          expect(result.success?).to eq(false)
          expect(result.errors.for(:transaction).on(:three_d_secure_authentication_id)[0].code).to eq(Braintree::ErrorCodes::Transaction::ThreeDSecureAuthenticationIdWithThreeDSecurePassThruIsInvalid)
        end
      end

      # NEXT_MAJOR_VERSION Remove these tests.
      # :three_d_secure_token is deprecated in favor of :three_d_secure_authentication_id
      context "with three_d_secure_token" do
        it "can create a transaction with a three_d_secure token" do
          three_d_secure_token = SpecHelper.create_3ds_verification(
            SpecHelper::ThreeDSecureMerchantAccountId,
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_month => "12",
            :expiration_year => "2012",
          )

          result = Braintree::Transaction.create(
            :merchant_account_id => SpecHelper::ThreeDSecureMerchantAccountId,
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "12/12",
            },
            :three_d_secure_token => three_d_secure_token,
          )

          expect(result.success?).to eq(true)
        end

        it "returns an error if sent a nil three_d_secure token" do
          result = Braintree::Transaction.create(
            :merchant_account_id => SpecHelper::ThreeDSecureMerchantAccountId,
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "12/12",
            },
            :three_d_secure_token => nil,
          )
          expect(result.success?).to eq(false)
          expect(result.errors.for(:transaction).on(:three_d_secure_token)[0].code).to eq(Braintree::ErrorCodes::Transaction::ThreeDSecureTokenIsInvalid)
        end

        it "returns an error if 3ds lookup data does not match txn data" do
          three_d_secure_token = SpecHelper.create_3ds_verification(
            SpecHelper::ThreeDSecureMerchantAccountId,
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_month => "12",
            :expiration_year => "2012",
          )

          result = Braintree::Transaction.create(
            :merchant_account_id => SpecHelper::ThreeDSecureMerchantAccountId,
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::MasterCard,
              :expiration_date => "12/12",
            },
            :three_d_secure_token => three_d_secure_token,
          )
          expect(result.success?).to eq(false)
          expect(result.errors.for(:transaction).on(:three_d_secure_token)[0].code).to eq(Braintree::ErrorCodes::Transaction::ThreeDSecureTransactionDataDoesntMatchVerify)
        end
      end

      it "can create a transaction with a three_d_secure_pass_thru" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :three_d_secure_pass_thru => {
            :eci_flag => "05",
            :cavv => "some_cavv",
            :xid => "some_xid",
            :three_d_secure_version => "1.0.2",
            :authentication_response => "Y",
            :directory_response => "Y",
            :cavv_algorithm => "2",
            :ds_transaction_id => "some_ds_id",
          },
        )

        expect(result.success?).to eq(true)
        expect(result.transaction.status).to eq(Braintree::Transaction::Status::Authorized)
      end

      it "returns an error for transaction with three_d_secure_pass_thru when processor settings do not support 3DS for card type" do
        result = Braintree::Transaction.create(
          :merchant_account_id => "heartland_ma",
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :three_d_secure_pass_thru => {
            :eci_flag => "05",
            :cavv => "some_cavv",
            :xid => "some_xid",
            :three_d_secure_version => "1.0.2",
            :authentication_response => "Y",
            :directory_response => "Y",
            :cavv_algorithm => "2",
            :ds_transaction_id => "some_ds_id",
          },
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).on(:merchant_account_id)[0].code).to eq(Braintree::ErrorCodes::Transaction::ThreeDSecureMerchantAccountDoesNotSupportCardType)
      end

      it "returns an error for transaction when the three_d_secure_pass_thru eci_flag is missing" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :three_d_secure_pass_thru => {
            :eci_flag => "",
            :cavv => "some_cavv",
            :xid => "some_xid",
          },
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:three_d_secure_pass_thru).on(:eci_flag)[0].code).to eq(Braintree::ErrorCodes::Transaction::ThreeDSecureEciFlagIsRequired)
      end

      it "returns an error for transaction when the three_d_secure_pass_thru cavv or xid is missing" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :three_d_secure_pass_thru => {
            :eci_flag => "05",
            :cavv => "",
            :xid => "",
            :three_d_secure_version => "1.0.2",
            :authentication_response => "Y",
            :directory_response => "Y",
            :cavv_algorithm => "2",
            :ds_transaction_id => "some_ds_id",
          },
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:three_d_secure_pass_thru).on(:cavv)[0].code).to eq(Braintree::ErrorCodes::Transaction::ThreeDSecureCavvIsRequired)
      end

      it "returns an error for transaction when the three_d_secure_pass_thru eci_flag is invalid" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :three_d_secure_pass_thru => {
            :eci_flag => "bad_eci_flag",
            :cavv => "some_cavv",
            :xid => "some_xid",
            :three_d_secure_version => "1.0.2",
            :authentication_response => "Y",
            :directory_response => "Y",
            :cavv_algorithm => "2",
            :ds_transaction_id => "some_ds_id",
          },
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:three_d_secure_pass_thru).on(:eci_flag)[0].code).to eq(Braintree::ErrorCodes::Transaction::ThreeDSecureEciFlagIsInvalid)
      end

      it "returns an error for transaction when the three_d_secure_pass_thru three_d_secure_version is invalid" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :three_d_secure_pass_thru => {
            :eci_flag => "05",
            :cavv => "some_cavv",
            :xid => "some_xid",
            :three_d_secure_version => "invalid",
            :authentication_response => "Y",
            :directory_response => "Y",
            :cavv_algorithm => "2",
            :ds_transaction_id => "some_ds_id",
          },
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:three_d_secure_pass_thru).on(:three_d_secure_version)[0].code).to eq(Braintree::ErrorCodes::Transaction::ThreeDSecureThreeDSecureVersionIsInvalid)
      end

      it "returns an error for transaction when the three_d_secure_pass_thru authentication_response is invalid" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :merchant_account_id => SpecHelper:: AdyenMerchantAccountId,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :three_d_secure_pass_thru => {
            :eci_flag => "05",
            :cavv => "some_cavv",
            :xid => "some_xid",
            :three_d_secure_version => "1.0.2",
            :authentication_response => "asdf",
            :directory_response => "Y",
            :cavv_algorithm => "2",
            :ds_transaction_id => "some_ds_id",
          },
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:three_d_secure_pass_thru).on(:authentication_response)[0].code).to eq(Braintree::ErrorCodes::Transaction::ThreeDSecureAuthenticationResponseIsInvalid)
      end

      it "returns an error for transaction when the three_d_secure_pass_thru directory_response is invalid" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :merchant_account_id => SpecHelper:: AdyenMerchantAccountId,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :three_d_secure_pass_thru => {
            :eci_flag => "05",
            :cavv => "some_cavv",
            :xid => "some_xid",
            :three_d_secure_version => "1.0.2",
            :authentication_response => "Y",
            :directory_response => "abc",
            :cavv_algorithm => "2",
            :ds_transaction_id => "some_ds_id",
          },
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:three_d_secure_pass_thru).on(:directory_response)[0].code).to eq(Braintree::ErrorCodes::Transaction::ThreeDSecureDirectoryResponseIsInvalid)
      end

      it "returns an error for transaction when the three_d_secure_pass_thru cavv_algorithm is invalid" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :merchant_account_id => SpecHelper:: AdyenMerchantAccountId,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :three_d_secure_pass_thru => {
            :eci_flag => "05",
            :cavv => "some_cavv",
            :xid => "some_xid",
            :three_d_secure_version => "1.0.2",
            :authentication_response => "Y",
            :directory_response => "Y",
            :cavv_algorithm => "bad_alg",
            :ds_transaction_id => "some_ds_id",
          },
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:three_d_secure_pass_thru).on(:cavv_algorithm)[0].code).to eq(Braintree::ErrorCodes::Transaction::ThreeDSecureCavvAlgorithmIsInvalid)
      end
    end

    context "paypal" do
      context "using a vaulted paypal account payment_method_token" do
        it "can create a transaction" do
          payment_method_result = Braintree::PaymentMethod.create(
            :customer_id => Braintree::Customer.create.customer.id,
            :payment_method_nonce => Braintree::Test::Nonce::PayPalBillingAgreement,
          )
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :payment_method_token => payment_method_result.payment_method.token,
          )

          expect(result).to be_success
          expect(result.transaction.payment_instrument_type).to eq(Braintree::PaymentInstrumentType::PayPalAccount)
          expect(result.transaction.paypal_details).not_to be_nil
          expect(result.transaction.paypal_details.debug_id).not_to be_nil
        end
      end

      context "future" do
        it "can create a paypal transaction with a nonce without vaulting" do
          payment_method_token = rand(36**3).to_s(36)
          nonce = nonce_for_paypal_account(
            :consent_code => "PAYPAL_CONSENT_CODE",
            :token => payment_method_token,
          )

          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :payment_method_nonce => nonce,
          )

          expect(result).to be_success
          expect(result.transaction.paypal_details).not_to be_nil
          expect(result.transaction.paypal_details.debug_id).not_to be_nil

          expect do
            Braintree::PaymentMethod.find(payment_method_token)
          end.to raise_error(Braintree::NotFoundError, "payment method with token \"#{payment_method_token}\" not found")
        end

        it "can create a paypal transaction and vault a paypal account" do
          payment_method_token = rand(36**3).to_s(36)
          nonce = nonce_for_paypal_account(
            :consent_code => "PAYPAL_CONSENT_CODE",
            :token => payment_method_token,
          )

          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :payment_method_nonce => nonce,
            :options => {:store_in_vault => true},
          )

          expect(result.success?).to eq(true)
          expect(result.transaction.paypal_details).not_to be_nil
          expect(result.transaction.paypal_details.debug_id).not_to be_nil

          found_paypal_account = Braintree::PaymentMethod.find(payment_method_token)
          expect(found_paypal_account).to be_a(Braintree::PayPalAccount)
          expect(found_paypal_account.token).to eq(payment_method_token)
        end
      end

      context "billing agreement" do
        it "can create a paypal billing agreement" do
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :payment_method_nonce => Braintree::Test::Nonce::PayPalBillingAgreement,
            :options => {:store_in_vault => true},
          )

          expect(result).to be_success
          expect(result.transaction.paypal_details).not_to be_nil
          expect(result.transaction.paypal_details.debug_id).not_to be_nil
          expect(result.transaction.paypal_details.billing_agreement_id).not_to be_nil
        end
      end

      context "local payments" do
        it "can create a local payment transaction with a nonce" do
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :payment_method_nonce => Braintree::Test::Nonce::LocalPayment,
          )

          expect(result).to be_success
          expect(result.transaction.local_payment_details).not_to be_nil
          expect(result.transaction.local_payment_details.funding_source).not_to be_nil
          expect(result.transaction.local_payment_details.payment_id).not_to be_nil
          expect(result.transaction.local_payment_details.capture_id).not_to be_nil
          expect(result.transaction.local_payment_details.transaction_fee_amount).not_to be_nil
          expect(result.transaction.local_payment_details.transaction_fee_currency_iso_code).not_to be_nil
        end
      end

      context "onetime" do
        it "can create a paypal transaction with a nonce" do
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
          )

          expect(result).to be_success
          expect(result.transaction.paypal_details).not_to be_nil
          expect(result.transaction.paypal_details.debug_id).not_to be_nil
        end

        it "can create a paypal transaction and does not vault even if asked to" do
          payment_method_token = rand(36**3).to_s(36)
          nonce = nonce_for_paypal_account(
            :access_token => "PAYPAL_ACCESS_TOKEN",
            :token => payment_method_token,
          )

          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :payment_method_nonce => nonce,
            :options => {:store_in_vault => true},
          )

          expect(result.success?).to eq(true)
          expect(result.transaction.paypal_details).not_to be_nil
          expect(result.transaction.paypal_details.debug_id).not_to be_nil

          expect do
            Braintree::PaymentMethod.find(payment_method_token)
          end.to raise_error(Braintree::NotFoundError, "payment method with token \"#{payment_method_token}\" not found")
        end
      end

      context "submit" do
        it "submits for settlement if instructed to do so" do
          result = Braintree::Transaction.sale(
            :amount => "100",
            :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
            :options => {
              :submit_for_settlement => true
            },
          )
          expect(result.success?).to eq(true)
          expect(result.transaction.status).to eq(Braintree::Transaction::Status::Settling)
        end
      end

      context "void" do
        it "successfully voids a paypal transaction that's been authorized" do
          sale_transaction = Braintree::Transaction.sale!(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
          )

          void_transaction = Braintree::Transaction.void!(sale_transaction.id)
          expect(void_transaction).to eq(sale_transaction)
          expect(void_transaction.status).to eq(Braintree::Transaction::Status::Voided)
        end

        it "fails to void a paypal transaction that's been declined" do
          sale_transaction = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Decline,
            :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
          ).transaction

          expect do
            Braintree::Transaction.void!(sale_transaction.id)
          end.to raise_error(Braintree::ValidationsFailed)
        end
      end

      describe "refund" do
        context "partial refunds" do
          it "allows partial refunds" do
            transaction = create_paypal_transaction_for_refund

            result = Braintree::Transaction.refund(transaction.id, transaction.amount / 2)
            expect(result).to be_success
            expect(result.transaction.type).to eq("credit")
          end

          it "allows multiple partial refunds" do
            transaction = create_paypal_transaction_for_refund

            transaction_1 = Braintree::Transaction.refund(transaction.id, transaction.amount / 2).transaction
            transaction_2 = Braintree::Transaction.refund(transaction.id, transaction.amount / 2).transaction

            transaction = Braintree::Transaction.find(transaction.id)
            expect(transaction.refund_ids.sort).to eq([transaction_1.id, transaction_2.id].sort)
          end

          it "allows partial refunds passed in an options hash" do
            transaction = create_paypal_transaction_for_refund

            transaction_1 = Braintree::Transaction.refund(transaction.id, :amount => transaction.amount / 2).transaction
            transaction_2 = Braintree::Transaction.refund(transaction.id, :amount => transaction.amount / 2).transaction

            transaction = Braintree::Transaction.find(transaction.id)
            expect(transaction.refund_ids.sort).to eq([transaction_1.id, transaction_2.id].sort)
          end
        end

        [Braintree::Test::CreditCardNumbers::Discover, Braintree::Test::CreditCardNumbers::Visa].each do |card_number|
          it "successfully refunds a transaction with AID" do
            transaction = Braintree::Transaction.sale!(
              :amount => Braintree::Test::TransactionAmounts::Authorize,
              :credit_card => {
                :number => card_number,
                :expiration_date => "05/2009"
              },
              :options => {
                :submit_for_settlement => true
              },
              :merchant_account_id => SpecHelper::FakeFirstDataMerchantAccountId,
              :industry => {
                :industry_type => Braintree::Transaction::IndustryType::TravelAndFlight,
                :data => {
                  :passenger_first_name => "John",
                  :passenger_last_name => "Doe",
                  :passenger_middle_initial => "M",
                  :passenger_title => "Mr.",
                  :issued_date => Date.new(2018, 1, 1),
                  :travel_agency_name => "Expedia",
                  :travel_agency_code => "12345678",
                  :ticket_number => "ticket-number",
                  :issuing_carrier_code => "AA",
                  :customer_code => "customer-code",
                  :fare_amount => 70_00,
                  :fee_amount => 10_00,
                  :tax_amount => 20_00,
                  :ticket_issuer_address => "Tkt-issuer-adr",
                  :arrival_date => Date.new(2020, 1, 2),
                  :restricted_ticket => false,
                  :legs => [
                    {
                      :conjunction_ticket => "CJ0001",
                      :exchange_ticket => "ET0001",
                      :coupon_number => "1",
                      :service_class => "Y",
                      :carrier_code => "AA",
                      :fare_basis_code => "W",
                      :flight_number => "AA100",
                      :departure_date => Date.new(2020, 1, 2),
                      :departure_airport_code => "MDW",
                      :departure_time => "08:00",
                      :arrival_airport_code => "ABC",
                      :arrival_time => "10:00",
                      :stopover_permitted => false,
                      :fare_amount => 35_00,
                      :fee_amount => 5_00,
                      :tax_amount => 10_00,
                      :endorsement_or_restrictions => "NOT REFUNDABLE",
                    },
                  ]
                },
              },
            )

            config = Braintree::Configuration.instantiate
            config.http.put("#{config.base_merchant_path}/transactions/#{transaction.id}/settle")
            transaction = Braintree::Transaction.find(transaction.id)

            result = Braintree::Transaction.refund(
              transaction.id,
              :merchant_account_id => SpecHelper::FakeFirstDataMerchantAccountId,
            )

            expect(result.success?).to eq(true)
            expect(result.transaction.type).to eq("credit")
          end
        end

        it "returns a successful result if successful" do
          transaction = create_paypal_transaction_for_refund

          result = Braintree::Transaction.refund(transaction.id)

          expect(result.success?).to eq(true)
          expect(result.transaction.type).to eq("credit")
        end

        it "allows an order_id to be passed for the refund" do
          transaction = create_paypal_transaction_for_refund

          result = Braintree::Transaction.refund(transaction.id, :order_id => "123458798123")

          expect(result.success?).to eq(true)
          expect(result.transaction.type).to eq("credit")
          expect(result.transaction.order_id).to eq("123458798123")
        end

        it "allows amount and order_id to be passed for the refund" do
          transaction = create_paypal_transaction_for_refund

          result = Braintree::Transaction.refund(transaction.id, :amount => transaction.amount/2, :order_id => "123458798123")

          expect(result.success?).to eq(true)
          expect(result.transaction.type).to eq("credit")
          expect(result.transaction.order_id).to eq("123458798123")
          expect(result.transaction.amount).to eq(transaction.amount/2)
        end

        it "allows merchant_account_id to be passed for the refund" do
          transaction = create_transaction_to_refund

          result = Braintree::Transaction.refund(
            transaction.id,
            :merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,
          )

          expect(result.success?).to eq(true)
          expect(result.transaction.type).to eq("credit")
          expect(result.transaction.merchant_account_id).to eq(SpecHelper::NonDefaultMerchantAccountId)
        end

        it "does not allow arbitrary options to be passed" do
          transaction = create_paypal_transaction_for_refund

          expect {
            Braintree::Transaction.refund(transaction.id, :blah => "123458798123")
          }.to raise_error(ArgumentError)
        end

        it "assigns the refunded_transaction_id to the original transaction" do
          transaction = create_paypal_transaction_for_refund
          refund_transaction = Braintree::Transaction.refund(transaction.id).transaction

          expect(refund_transaction.refunded_transaction_id).to eq(transaction.id)
        end

        it "returns an error result if unsettled" do
          transaction = Braintree::Transaction.sale!(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
          )
          result = Braintree::Transaction.refund(transaction.id)
          expect(result.success?).to eq(false)
          expect(result.errors.for(:transaction).on(:base)[0].code).to eq(Braintree::ErrorCodes::Transaction::CannotRefundUnlessSettled)
        end

        it "handles soft declined refund authorizations" do
          transaction = Braintree::Transaction.sale!(
            :amount => "9000.00",
            :payment_method_nonce => Braintree::Test::Nonce::Transactable,
            :options => {
              :submit_for_settlement => true
            },
          )
          config = Braintree::Configuration.instantiate
          config.http.put("#{config.base_merchant_path}/transactions/#{transaction.id}/settle")
          result = Braintree::Transaction.refund(transaction.id, :amount => "2046.00")
          expect(result.success?).to eq(false)
          expect(result.transaction.id).to match(/^\w{6,}$/)
          expect(result.transaction.type).to eq("credit")
          expect(result.transaction.status).to eq(Braintree::Transaction::Status::ProcessorDeclined)
          expect(result.transaction.processor_response_code).to eq("2046")
          expect(result.transaction.processor_response_text).to eq("Declined")
          expect(result.transaction.processor_response_type).to eq(Braintree::ProcessorResponseTypes::SoftDeclined)
          expect(result.transaction.additional_processor_response).to eq("2046 : Declined")
        end

        it "handles hard declined refund authorizations" do
          transaction = Braintree::Transaction.sale!(
            :amount => "9000.00",
            :payment_method_nonce => Braintree::Test::Nonce::Transactable,
            :options => {
              :submit_for_settlement => true
            },
          )
          config = Braintree::Configuration.instantiate
          config.http.put("#{config.base_merchant_path}/transactions/#{transaction.id}/settle")
          result = Braintree::Transaction.refund(transaction.id, :amount => "2009.00")
          expect(result.success?).to eq(false)
          expect(result.transaction.id).to match(/^\w{6,}$/)
          expect(result.transaction.type).to eq("credit")
          expect(result.transaction.status).to eq(Braintree::Transaction::Status::ProcessorDeclined)
          expect(result.transaction.processor_response_code).to eq("2009")
          expect(result.transaction.processor_response_text).to eq("No Such Issuer")
          expect(result.transaction.processor_response_type).to eq(Braintree::ProcessorResponseTypes::HardDeclined)
          expect(result.transaction.additional_processor_response).to eq("2009 : No Such Issuer")
        end
      end

      context "handling errors" do
        it "handles bad unvalidated nonces" do
          nonce = nonce_for_paypal_account(
            :access_token => "PAYPAL_ACCESS_TOKEN",
            :consent_code => "PAYPAL_CONSENT_CODE",
          )

          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :payment_method_nonce => nonce,
          )

          expect(result).not_to be_success
          expect(result.errors.for(:transaction).for(:paypal_account).first.code).to eq("82903")
        end

        it "handles non-existent nonces" do
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :payment_method_nonce => "NON_EXISTENT_NONCE",
          )

          expect(result).not_to be_success
          expect(result.errors.for(:transaction).first.code).to eq("91565")
        end
      end
    end

    context "line items" do
      it "allows creation with empty line items and returns none" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [],
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.line_items).to eq([])
      end

      it "allows creation with single line item with minimal fields and returns it" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "45.15",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.0232",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :total_amount => "45.15",
            },
          ],
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.line_items.length).to eq(1)
        line_item = result.transaction.line_items[0]
        expect(line_item.quantity).to eq(BigDecimal("1.0232"))
        expect(line_item.name).to eq("Name #1")
        expect(line_item.kind).to eq("debit")
        expect(line_item.unit_amount).to eq(BigDecimal("45.1232"))
        expect(line_item.total_amount).to eq(BigDecimal("45.15"))
      end

      it "allows creation with single line item with zero amount fields and returns it" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "45.15",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.0232",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :total_amount => "45.15",
              :unit_tax_amount => "0",
              :discount_amount => "0",
              :tax_amount => "0",
            },
          ],
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.line_items.length).to eq(1)
        line_item = result.transaction.line_items[0]
        expect(line_item.quantity).to eq(BigDecimal("1.0232"))
        expect(line_item.name).to eq("Name #1")
        expect(line_item.kind).to eq("debit")
        expect(line_item.unit_amount).to eq(BigDecimal("45.1232"))
        expect(line_item.total_amount).to eq(BigDecimal("45.15"))
        expect(line_item.unit_tax_amount).to eq(BigDecimal("0"))
        expect(line_item.discount_amount).to eq(BigDecimal("0"))
        expect(line_item.tax_amount).to eq(BigDecimal("0"))
      end

      it "allows creation with single line item and returns it" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "45.15",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.0232",
              :name => "Name #1",
              :description => "Description #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_tax_amount => "1.23",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :tax_amount => "4.50",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
              :url => "https://example.com/products/23434",
            },
          ],
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.line_items.length).to eq(1)
        line_item = result.transaction.line_items[0]
        expect(line_item.quantity).to eq(BigDecimal("1.0232"))
        expect(line_item.name).to eq("Name #1")
        expect(line_item.description).to eq("Description #1")
        expect(line_item.kind).to eq("debit")
        expect(line_item.unit_amount).to eq(BigDecimal("45.1232"))
        expect(line_item.unit_tax_amount).to eq(BigDecimal("1.23"))
        expect(line_item.unit_of_measure).to eq("gallon")
        expect(line_item.discount_amount).to eq(BigDecimal("1.02"))
        expect(line_item.tax_amount).to eq(BigDecimal("4.50"))
        expect(line_item.total_amount).to eq(BigDecimal("45.15"))
        expect(line_item.product_code).to eq("23434")
        expect(line_item.commodity_code).to eq("9SAASSD8724")
        expect(line_item.url).to eq("https://example.com/products/23434")
      end

      it "allows creation with multiple line items and returns them" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.0232",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :tax_amount => "4.50",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "2.02",
              :name => "Name #2",
              :kind => "credit",
              :unit_amount => "5",
              :unit_of_measure => "gallon",
              :tax_amount => "1.50",
              :total_amount => "10.1",
            },
          ],
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.line_items.length).to eq(2)
        line_item_1 = result.transaction.line_items.find { |line_item| line_item.name == "Name #1" }
        expect(line_item_1.quantity).to eq(BigDecimal("1.0232"))
        expect(line_item_1.name).to eq("Name #1")
        expect(line_item_1.kind).to eq("debit")
        expect(line_item_1.unit_amount).to eq(BigDecimal("45.1232"))
        expect(line_item_1.unit_of_measure).to eq("gallon")
        expect(line_item_1.discount_amount).to eq(BigDecimal("1.02"))
        expect(line_item_1.tax_amount).to eq(BigDecimal("4.50"))
        expect(line_item_1.total_amount).to eq(BigDecimal("45.15"))
        expect(line_item_1.product_code).to eq("23434")
        expect(line_item_1.commodity_code).to eq("9SAASSD8724")
        line_item_2 = result.transaction.line_items.find { |line_item| line_item.name == "Name #2" }
        expect(line_item_2.quantity).to eq(BigDecimal("2.02"))
        expect(line_item_2.name).to eq("Name #2")
        expect(line_item_2.kind).to eq("credit")
        expect(line_item_2.unit_amount).to eq(BigDecimal("5"))
        expect(line_item_2.unit_of_measure).to eq("gallon")
        expect(line_item_2.total_amount).to eq(BigDecimal("10.1"))
        expect(line_item_2.tax_amount).to eq(BigDecimal("1.50"))
        expect(line_item_2.discount_amount).to eq(nil)
        expect(line_item_2.product_code).to eq(nil)
        expect(line_item_2.commodity_code).to eq(nil)
      end

      it "handles validation error commodity code is too long" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1.2322",
              :name => "Name #2",
              :kind => "credit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "1234567890123",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:commodity_code)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::CommodityCodeIsTooLong)
      end

      it "handles validation error description is too long" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1.2322",
              :name => "Name #2",
              :description => "X" * 128,
              :kind => "credit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:description)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::DescriptionIsTooLong)
      end

      it "handles validation error discount amount format is invalid" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1.2322",
              :name => "Name #2",
              :kind => "credit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "$1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:discount_amount)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::DiscountAmountFormatIsInvalid)
      end

      it "handles validation error discount amount is too large" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1.2322",
              :name => "Name #2",
              :kind => "credit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "2147483648",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:discount_amount)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::DiscountAmountIsTooLarge)
      end

      it "handles validation error discount amount cannot be negative" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1.2322",
              :name => "Name #2",
              :kind => "credit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "-2",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:discount_amount)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::DiscountAmountCannotBeNegative)
      end

      it "handles validation error tax amount format is invalid" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :tax_amount => "$1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_0).on(:tax_amount)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::TaxAmountFormatIsInvalid)
      end

      it "handles validation error tax amount is too large" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :tax_amount => "2147483648",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_0).on(:tax_amount)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::TaxAmountIsTooLarge)
      end

      it "handles validation error tax amount cannot be negative" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :tax_amount => "-2",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_0).on(:tax_amount)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::TaxAmountCannotBeNegative)
      end

      it "handles validation error kind is invalid" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1.2322",
              :name => "Name #2",
              :kind => "sale",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:kind)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::KindIsInvalid)
      end

      it "handles validation error kind is required" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1.2322",
              :name => "Name #2",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:kind)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::KindIsRequired)
      end

      it "handles validation error name is required" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1.2322",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:name)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::NameIsRequired)
      end

      it "handles validation error name is too long" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1.2322",
              :name => "X"*36,
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:name)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::NameIsTooLong)
      end

      it "handles validation error product code is too long" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1.2322",
              :name => "Name #2",
              :kind => "credit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "1234567890123",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:product_code)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::ProductCodeIsTooLong)
      end

      it "handles validation error quantity format is invalid" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1,2322",
              :name => "Name #2",
              :kind => "credit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:quantity)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::QuantityFormatIsInvalid)
      end

      it "handles validation error quantity is required" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :name => "Name #2",
              :kind => "credit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:quantity)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::QuantityIsRequired)
      end

      it "handles validation error quantity is too large" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "2147483648",
              :name => "Name #2",
              :kind => "credit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:quantity)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::QuantityIsTooLarge)
      end

      it "handles validation error total amount format is invalid" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1.2322",
              :name => "Name #2",
              :kind => "credit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "$45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:total_amount)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::TotalAmountFormatIsInvalid)
      end

      it "handles validation error total amount is required" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1.2322",
              :name => "Name #2",
              :kind => "credit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:total_amount)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::TotalAmountIsRequired)
      end

      it "handles validation error total amount is too large" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1.2322",
              :name => "Name #2",
              :kind => "credit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "2147483648",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:total_amount)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::TotalAmountIsTooLarge)
      end

      it "handles validation error total amount must be greater than zero" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1.2322",
              :name => "Name #2",
              :kind => "credit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "-2",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:total_amount)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::TotalAmountMustBeGreaterThanZero)
      end

      it "handles validation error unit amount format is invalid" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1.2322",
              :name => "Name #2",
              :kind => "credit",
              :unit_amount => "45.01232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:unit_amount)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::UnitAmountFormatIsInvalid)
      end

      it "handles validation error unit amount is required" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1.2322",
              :name => "Name #2",
              :kind => "credit",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:unit_amount)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::UnitAmountIsRequired)
      end

      it "handles validation error unit amount is too large" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1.2322",
              :name => "Name #2",
              :kind => "credit",
              :unit_amount => "2147483648",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:unit_amount)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::UnitAmountIsTooLarge)
      end

      it "handles validation error unit amount must be greater than zero" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1.2322",
              :name => "Name #2",
              :kind => "credit",
              :unit_amount => "-2",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:unit_amount)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::UnitAmountMustBeGreaterThanZero)
      end

      it "handles validation error unit of measure is too long" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1.2322",
              :name => "Name #2",
              :kind => "credit",
              :unit_amount => "45.1232",
              :unit_of_measure => "1234567890123",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:unit_of_measure)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::UnitOfMeasureIsTooLong)
      end

      it "handles validation error unit tax amount format is invalid" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_tax_amount => "2.34",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1.2322",
              :name => "Name #2",
              :kind => "credit",
              :unit_amount => "45.0122",
              :unit_tax_amount => "2.012",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:unit_tax_amount)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::UnitTaxAmountFormatIsInvalid)
      end

      it "handles validation error unit tax amount is too large" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_tax_amount => "1.23",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1.2322",
              :name => "Name #2",
              :kind => "credit",
              :unit_amount => "45.0122",
              :unit_tax_amount => "2147483648",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:unit_tax_amount)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::UnitTaxAmountIsTooLarge)
      end

      it "handles validation error unit tax amount cannot be negative" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => [
            {
              :quantity => "1.2322",
              :name => "Name #1",
              :kind => "debit",
              :unit_amount => "45.1232",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
            {
              :quantity => "1.2322",
              :name => "Name #2",
              :kind => "credit",
              :unit_amount => "45.0122",
              :unit_tax_amount => "-1.23",
              :unit_of_measure => "gallon",
              :discount_amount => "1.02",
              :total_amount => "45.15",
              :product_code => "23434",
              :commodity_code => "9SAASSD8724",
            },
          ],
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:line_items).for(:index_1).on(:unit_tax_amount)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::UnitTaxAmountCannotBeNegative)
      end

      it "handles validation errors on line items structure" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => {
            :quantity => "2.02",
            :name => "Name #2",
            :kind => "credit",
            :unit_amount => "5",
            :unit_of_measure => "gallon",
            :total_amount => "10.1",
          },
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).on(:line_items)[0].code).to eq(Braintree::ErrorCodes::Transaction::LineItemsExpected)
      end

      it "handles invalid arguments on line items structure" do
        expect do
          Braintree::Transaction.create(
            :type => "sale",
            :amount => "35.05",
            :payment_method_nonce => Braintree::Test::Nonce::Transactable,
            :line_items => [
              {
                :quantity => "2.02",
                :name => "Name #1",
                :kind => "credit",
                :unit_amount => "5",
                :unit_of_measure => "gallon",
                :total_amount => "10.1",
              },
              ["Name #2"],
              {
                :quantity => "2.02",
                :name => "Name #3",
                :kind => "credit",
                :unit_amount => "5",
                :unit_of_measure => "gallon",
                :total_amount => "10.1",
              },
            ],
          )
        end.to raise_error(ArgumentError)
      end

      it "handles validation errors on too many line items" do
        line_items = 250.times.map do |i|
          {
            :quantity => "2.02",
            :name => "Line item ##{i}",
            :kind => "credit",
            :unit_amount => "5",
            :unit_of_measure => "gallon",
            :total_amount => "10.1",
          }
        end
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => "35.05",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :line_items => line_items,
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).on(:line_items)[0].code).to eq(Braintree::ErrorCodes::Transaction::TooManyLineItems)
      end

      context "UPC code and type" do
        let(:line_item) do
          {
            :quantity => "1",
            :name => "Name #1",
            :description => "Description #1",
            :kind => "debit",
            :unit_amount => "45.12",
            :unit_tax_amount => "1.23",
            :unit_of_measure => "gallon",
            :discount_amount => "1.02",
            :tax_amount => "4.50",
            :total_amount => "45.15",
            :product_code => "23434",
            :commodity_code => "9SAASSD8724",
            :url => "https://example.com/products/23434",
            :upc_code => "042100005264",
            :upc_type => "UPC-A",
            :image_url => "https://google.com/image.png",
          }
        end

        it "accepts valid values" do
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => "45.15",
            :payment_method_nonce => Braintree::Test::Nonce::Transactable,
            :line_items => [line_item],
          )
          expect(result.success?).to eq(true)
          expect(result.transaction.line_items.length).to eq(1)
          line_item = result.transaction.line_items[0]
          expect(line_item.upc_code).to eq("042100005264")
          expect(line_item.upc_type).to eq("UPC-A")
        end

        it "returns validation errors for invalid UPC code and type too long" do
          line_item[:upc_code] = "THISCODELONGERTHAN17CHARS"
          line_item[:upc_type] = "USB-C"
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => "45.15",
            :payment_method_nonce => Braintree::Test::Nonce::Transactable,
            :line_items => [line_item],
          )

          expect(result.success?).to eq(false)
          expect(result.errors.for(:transaction).for(:line_items).for(:index_0).on(:upc_code)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::UPCCodeIsTooLong)
          expect(result.errors.for(:transaction).for(:line_items).for(:index_0).on(:upc_type)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::UPCTypeIsInvalid)
        end

        it "returns UPC code missing error when code is not present" do
          line_item.delete(:upc_code)
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => "45.15",
            :payment_method_nonce => Braintree::Test::Nonce::Transactable,
            :line_items => [line_item],
          )

          expect(result.success?).to eq(false)
          expect(result.errors.for(:transaction).for(:line_items).for(:index_0).on(:upc_code)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::UPCCodeIsMissing)
        end

        it "returns UPC type missing error when type is not present" do
          line_item.delete(:upc_type)
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => "45.15",
            :payment_method_nonce => Braintree::Test::Nonce::Transactable,
            :line_items => [line_item],
          )

          expect(result.success?).to eq(false)
          expect(result.errors.for(:transaction).for(:line_items).for(:index_0).on(:upc_type)[0].code).to eq(Braintree::ErrorCodes::TransactionLineItem::UPCTypeIsMissing)
        end
      end
    end

    context "level 3 summary data" do
      it "accepts level 3 summary data" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :amount => "10.00",
          :shipping_amount => "1.00",
          :discount_amount => "2.00",
          :ships_from_postal_code => "12345",
        )

        expect(result.success?).to eq(true)
        expect(result.transaction.shipping_amount).to eq("1.00")
        expect(result.transaction.discount_amount).to eq("2.00")
        expect(result.transaction.ships_from_postal_code).to eq("12345")
      end

      it "handles validation errors on summary data" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :amount => "10.00",
          :shipping_amount => "1a00",
          :discount_amount => "-2.00",
          :ships_from_postal_code => "1$345",
        )

        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).on(:shipping_amount)[0].code).to eq(Braintree::ErrorCodes::Transaction::ShippingAmountFormatIsInvalid)
        expect(result.errors.for(:transaction).on(:discount_amount)[0].code).to eq(Braintree::ErrorCodes::Transaction::DiscountAmountCannotBeNegative)
        expect(result.errors.for(:transaction).on(:ships_from_postal_code)[0].code).to eq(Braintree::ErrorCodes::Transaction::ShipsFromPostalCodeInvalidCharacters)
      end

      it "handles validation error discount amount format is invalid" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :amount => "10.00",
          :discount_amount => "2.001",
        )

        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).on(:discount_amount)[0].code).to eq(Braintree::ErrorCodes::Transaction::DiscountAmountFormatIsInvalid)
      end

      it "handles validation error discount amount cannot be negative" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :amount => "10.00",
          :discount_amount => "-2",
        )

        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).on(:discount_amount)[0].code).to eq(Braintree::ErrorCodes::Transaction::DiscountAmountCannotBeNegative)
      end

      it "handles validation error discount amount is too large" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :amount => "10.00",
          :discount_amount => "2147483648",
        )

        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).on(:discount_amount)[0].code).to eq(Braintree::ErrorCodes::Transaction::DiscountAmountIsTooLarge)
      end

      it "handles validation error shipping amount format is invalid" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :amount => "10.00",
          :shipping_amount => "2.001",
        )

        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).on(:shipping_amount)[0].code).to eq(Braintree::ErrorCodes::Transaction::ShippingAmountFormatIsInvalid)
      end

      it "handles validation error shipping amount cannot be negative" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :amount => "10.00",
          :shipping_amount => "-2",
        )

        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).on(:shipping_amount)[0].code).to eq(Braintree::ErrorCodes::Transaction::ShippingAmountCannotBeNegative)
      end

      it "handles validation error shipping amount is too large" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :amount => "10.00",
          :shipping_amount => "2147483648",
        )

        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).on(:shipping_amount)[0].code).to eq(Braintree::ErrorCodes::Transaction::ShippingAmountIsTooLarge)
      end

      it "handles validation error ships from postal code is too long" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :amount => "10.00",
          :ships_from_postal_code => "1234567890",
        )

        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).on(:ships_from_postal_code)[0].code).to eq(Braintree::ErrorCodes::Transaction::ShipsFromPostalCodeIsTooLong)
      end

      it "handles validation error ships from postal code invalid characters" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :payment_method_nonce => Braintree::Test::Nonce::Transactable,
          :amount => "10.00",
          :ships_from_postal_code => "12345%78",
        )

        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).on(:ships_from_postal_code)[0].code).to eq(Braintree::ErrorCodes::Transaction::ShipsFromPostalCodeInvalidCharacters)
      end
    end

    context "network_transaction_id" do
      it "receives network_transaction_id for visa transaction" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
          :amount => "10.00",
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.network_transaction_id).not_to be_nil
      end
    end

    context "external vault" do
      it "returns a validation error if used with an unsupported instrument type" do
        customer = Braintree::Customer.create!
        result = Braintree::PaymentMethod.create(
          :payment_method_nonce => Braintree::Test::Nonce::PayPalBillingAgreement,
          :customer_id => customer.id,
        )
        payment_method_token = result.payment_method.token

        result = Braintree::Transaction.create(
          :type => "sale",
          :customer_id => customer.id,
          :payment_method_token => payment_method_token,
          :external_vault => {
            :status => Braintree::Transaction::ExternalVault::Status::WillVault,
          },
          :amount => "10.00",
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction)[0].code).to eq(Braintree::ErrorCodes::Transaction::PaymentInstrumentWithExternalVaultIsInvalid)
      end

      it "reject invalid status" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::MasterCard,
            :expiration_date => "05/2009"
          },
          :external_vault => {
            :status => "not_valid",
          },
          :amount => "10.00",
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:external_vault).on(:status)[0].code).to eq(Braintree::ErrorCodes::Transaction::ExternalVault::StatusIsInvalid)
      end

      context "Visa/Mastercard/Discover/AmEx" do
        it "accepts status" do
          result = Braintree::Transaction.create(
            :type => "sale",
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "05/2009"
            },
            :external_vault => {
              :status => Braintree::Transaction::ExternalVault::Status::WillVault,
            },
            :amount => "10.00",
          )
          expect(result.success?).to eq(true)
          expect(result.transaction.network_transaction_id).not_to be_nil
        end

        it "accepts previous_network_transaction_id" do
          result = Braintree::Transaction.create(
            :type => "sale",
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::MasterCard,
              :expiration_date => "05/2009"
            },
            :external_vault => {
              :status => Braintree::Transaction::ExternalVault::Status::Vaulted,
              :previous_network_transaction_id => "123456789012345",
            },
            :amount => "10.00",
          )
          expect(result.success?).to eq(true)
          expect(result.transaction.network_transaction_id).not_to be_nil
        end

        it "rejects non-vaulted status with previous_network_transaction_id" do
          result = Braintree::Transaction.create(
            :type => "sale",
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Discover,
              :expiration_date => "05/2009"
            },
            :external_vault => {
              :status => Braintree::Transaction::ExternalVault::Status::WillVault,
              :previous_network_transaction_id => "123456789012345",
            },
            :amount => "10.00",
          )
          expect(result.success?).to eq(false)
          expect(result.errors.for(:transaction).for(:external_vault).on(:status)[0].code).to eq(Braintree::ErrorCodes::Transaction::ExternalVault::StatusWithPreviousNetworkTransactionIdIsInvalid)
        end
      end

      context "Non-(Visa/Mastercard/Discover/AmEx) card types" do
        it "accepts status" do
          result = Braintree::Transaction.create(
            :type => "sale",
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::JCBs[0],
              :expiration_date => "05/2009"
            },
            :external_vault => {
              :status => Braintree::Transaction::ExternalVault::Status::WillVault,
            },
            :amount => "10.00",
          )
          expect(result.success?).to eq(true)
          expect(result.transaction.network_transaction_id).not_to be_nil
        end

        it "accepts blank previous_network_transaction_id" do
          result = Braintree::Transaction.create(
            :type => "sale",
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::JCBs[0],
              :expiration_date => "05/2009"
            },
            :external_vault => {
              :status => Braintree::Transaction::ExternalVault::Status::Vaulted,
              :previous_network_transaction_id => "",
            },
            :amount => "10.00",
          )
          expect(result.success?).to eq(true)
          expect(result.transaction.network_transaction_id).not_to be_nil
        end
      end
    end

    context "account_type" do
      it "creates a Hiper transaction with account type credit" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :merchant_account_id => SpecHelper::HiperBRLMerchantAccountId,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Hiper,
            :expiration_date => "05/2009"
          },
          :amount => "10.00",
          :options => {
            :credit_card => {
              :account_type => "credit",
            }
          },
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.credit_card_details.account_type).to eq("credit")
      end

      it "creates a Hipercard transaction with account_type credit" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :merchant_account_id => SpecHelper::HiperBRLMerchantAccountId,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Hipercard,
            :expiration_date => "05/2009"
          },
          :amount => "10.00",
          :options => {
            :credit_card => {
              :account_type => "credit",
            }
          },
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.credit_card_details.account_type).to eq("credit")
      end

      it "creates a Hiper transaction with account_type debit" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :merchant_account_id => SpecHelper::HiperBRLMerchantAccountId,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Hiper,
            :expiration_date => "05/2009"
          },
          :amount => "10.00",
          :options => {
            :credit_card => {
              :account_type => "debit",
            },
            :submit_for_settlement => true,
          },
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.credit_card_details.account_type).to eq("debit")
      end

      it "does not allow auths with account_type debit" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :merchant_account_id => SpecHelper::HiperBRLMerchantAccountId,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Hiper,
            :expiration_date => "05/2009"
          },
          :amount => "10.00",
          :options => {
            :credit_card => {
              :account_type => "debit",
            },
          },
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:options).for(:credit_card).on(:account_type)[0].code).to eq(Braintree::ErrorCodes::Transaction::Options::CreditCard::AccountTypeDebitDoesNotSupportAuths)
      end

      it "does not allow invalid account_type" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :merchant_account_id => SpecHelper::HiperBRLMerchantAccountId,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Hiper,
            :expiration_date => "05/2009"
          },
          :amount => "10.00",
          :options => {
            :credit_card => {
              :account_type => "ach",
            },
          },
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:options).for(:credit_card).on(:account_type)[0].code).to eq(Braintree::ErrorCodes::Transaction::Options::CreditCard::AccountTypeIsInvalid)
      end

      it "does not allow account_type not supported by merchant" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
          :amount => "10.00",
          :options => {
            :credit_card => {
              :account_type => "credit",
            },
          },
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:options).for(:credit_card).on(:account_type)[0].code).to eq(Braintree::ErrorCodes::Transaction::Options::CreditCard::AccountTypeNotSupported)
      end
    end
  end

  describe "self.create!" do
    it "returns the transaction if valid" do
      transaction = Braintree::Transaction.create!(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )
      expect(transaction.id).to match(/^\w{6,}$/)
      expect(transaction.type).to eq("sale")
      expect(transaction.amount).to eq(BigDecimal(Braintree::Test::TransactionAmounts::Authorize))
      expect(transaction.credit_card_details.bin).to eq(Braintree::Test::CreditCardNumbers::Visa[0, 6])
      expect(transaction.credit_card_details.last_4).to eq(Braintree::Test::CreditCardNumbers::Visa[-4..-1])
      expect(transaction.credit_card_details.expiration_date).to eq("05/2009")
    end

    it "raises a validationsfailed if invalid" do
      expect do
        Braintree::Transaction.create!(
          :type => "sale",
          :amount => nil,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
        )
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.refund" do
    context "partial refunds" do
      it "allows partial refunds" do
        transaction = create_transaction_to_refund
        result = Braintree::Transaction.refund(transaction.id, transaction.amount / 2)
        expect(result.success?).to eq(true)
        expect(result.transaction.type).to eq("credit")
      end

      it "allows multiple partial refunds" do
        transaction = create_transaction_to_refund
        transaction_1 = Braintree::Transaction.refund(transaction.id, transaction.amount / 2).transaction
        transaction_2 = Braintree::Transaction.refund(transaction.id, transaction.amount / 2).transaction

        transaction = Braintree::Transaction.find(transaction.id)
        expect(transaction.refund_ids.sort).to eq([transaction_1.id, transaction_2.id].sort)
      end
    end

    it "returns a successful result if successful" do
      transaction = create_transaction_to_refund
      expect(transaction.status).to eq(Braintree::Transaction::Status::Settled)
      result = Braintree::Transaction.refund(transaction.id)
      expect(result.success?).to eq(true)
      expect(result.transaction.type).to eq("credit")
    end

    it "assigns the refunded_transaction_id to the original transaction" do
      transaction = create_transaction_to_refund
      refund_transaction = Braintree::Transaction.refund(transaction.id).transaction

      expect(refund_transaction.refunded_transaction_id).to eq(transaction.id)
    end

    it "returns an error if already refunded" do
      transaction = create_transaction_to_refund
      result = Braintree::Transaction.refund(transaction.id)
      expect(result.success?).to eq(true)
      result = Braintree::Transaction.refund(transaction.id)
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:base)[0].code).to eq(Braintree::ErrorCodes::Transaction::HasAlreadyBeenRefunded)
    end

    it "returns an error result if unsettled" do
      transaction = Braintree::Transaction.create!(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )
      result = Braintree::Transaction.refund(transaction.id)
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:base)[0].code).to eq(Braintree::ErrorCodes::Transaction::CannotRefundUnlessSettled)
    end
  end

  describe "self.refund!" do
    it "returns the refund if valid refund" do
      transaction = create_transaction_to_refund

      refund_transaction = Braintree::Transaction.refund!(transaction.id)

      expect(refund_transaction.refunded_transaction_id).to eq(transaction.id)
      expect(refund_transaction.type).to eq("credit")
      expect(transaction.amount).to eq(refund_transaction.amount)
    end

    it "raises a ValidationsFailed if invalid" do
      transaction = create_transaction_to_refund
      invalid_refund_amount = transaction.amount + 1
      expect(invalid_refund_amount).to be > transaction.amount

      expect do
        Braintree::Transaction.refund!(transaction.id,invalid_refund_amount)
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.sale" do
    it "returns a successful result with type=sale if successful" do
      result = Braintree::Transaction.sale(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )
      expect(result.success?).to eq(true)
      expect(result.transaction.id).to match(/^\w{6,}$/)
      expect(result.transaction.type).to eq("sale")
      expect(result.transaction.amount).to eq(BigDecimal(Braintree::Test::TransactionAmounts::Authorize))
      expect(result.transaction.credit_card_details.bin).to eq(Braintree::Test::CreditCardNumbers::Visa[0, 6])
      expect(result.transaction.credit_card_details.last_4).to eq(Braintree::Test::CreditCardNumbers::Visa[-4..-1])
      expect(result.transaction.credit_card_details.expiration_date).to eq("05/2009")
    end

    it "works when given all attributes" do
      result = Braintree::Transaction.sale(
        :amount => "100.00",
        :order_id => "123",
        :product_sku => "productsku01",
        :channel => "MyShoppingCartProvider",
        :credit_card => {
          :cardholder_name => "The Cardholder",
          :number => "5105105105105100",
          :expiration_date => "05/2011",
          :cvv => "123"
        },
        :customer => {
          :first_name => "Dan",
          :last_name => "Smith",
          :company => "Braintree",
          :email => "dan@example.com",
          :phone => "419-555-1234",
          :fax => "419-555-1235",
          :website => "http://braintreepayments.com"
        },
        :billing => {
          :first_name => "Carl",
          :last_name => "Jones",
          :company => "Braintree",
          :street_address => "123 E Main St",
          :extended_address => "Suite 403",
          :locality => "Chicago",
          :region => "IL",
          :phone_number => "122-555-1237",
          :international_phone => {:country_code => "1", :national_number => "3121234567"},
          :postal_code => "60622",
          :country_name => "United States of America"
        },
        :shipping => {
          :first_name => "Andrew",
          :last_name => "Mason",
          :company => "Braintree",
          :street_address => "456 W Main St",
          :extended_address => "Apt 2F",
          :locality => "Bartlett",
          :region => "IL",
          :phone_number => "122-555-1236",
          :international_phone => {:country_code => "1", :national_number => "3121234567"},
          :postal_code => "60103",
          :country_name => "United States of America",
          :shipping_method => Braintree::Transaction::AddressDetails::ShippingMethod::Electronic
        },
      )
      expect(result.success?).to eq(true)
      transaction = result.transaction
      expect(transaction.id).to match(/\A\w{6,}\z/)
      expect(transaction.type).to eq("sale")
      expect(transaction.status).to eq(Braintree::Transaction::Status::Authorized)
      expect(transaction.amount).to eq(BigDecimal("100.00"))
      expect(transaction.currency_iso_code).to eq("USD")
      expect(transaction.order_id).to eq("123")
      expect(transaction.channel).to eq("MyShoppingCartProvider")
      expect(transaction.processor_response_code).to eq("1000")
      expect(transaction.authorization_expires_at.between?(Time.now, Time.now + (60 * 60 * 24 * 60))).to eq(true)
      expect(transaction.created_at.between?(Time.now - 60, Time.now)).to eq(true)
      expect(transaction.updated_at.between?(Time.now - 60, Time.now)).to eq(true)
      expect(transaction.credit_card_details.bin).to eq("510510")
      expect(transaction.credit_card_details.cardholder_name).to eq("The Cardholder")
      expect(transaction.credit_card_details.last_4).to eq("5100")
      expect(transaction.credit_card_details.masked_number).to eq("510510******5100")
      expect(transaction.credit_card_details.card_type).to eq("MasterCard")
      expect(transaction.avs_error_response_code).to eq(nil)
      expect(transaction.avs_postal_code_response_code).to eq("M")
      expect(transaction.avs_street_address_response_code).to eq("M")
      expect(transaction.cvv_response_code).to eq("M")
      expect(transaction.customer_details.first_name).to eq("Dan")
      expect(transaction.customer_details.last_name).to eq("Smith")
      expect(transaction.customer_details.company).to eq("Braintree")
      expect(transaction.customer_details.email).to eq("dan@example.com")
      expect(transaction.customer_details.phone).to eq("419-555-1234")
      expect(transaction.customer_details.fax).to eq("419-555-1235")
      expect(transaction.customer_details.website).to eq("http://braintreepayments.com")
      expect(transaction.billing_details.first_name).to eq("Carl")
      expect(transaction.billing_details.last_name).to eq("Jones")
      expect(transaction.billing_details.company).to eq("Braintree")
      expect(transaction.billing_details.street_address).to eq("123 E Main St")
      expect(transaction.billing_details.extended_address).to eq("Suite 403")
      expect(transaction.billing_details.locality).to eq("Chicago")
      expect(transaction.billing_details.region).to eq("IL")
      expect(transaction.billing_details.postal_code).to eq("60622")
      expect(transaction.billing_details.country_name).to eq("United States of America")
      expect(transaction.billing_details.country_code_alpha2).to eq("US")
      expect(transaction.billing_details.country_code_alpha3).to eq("USA")
      expect(transaction.billing_details.country_code_numeric).to eq("840")
      expect(transaction.billing_details.phone_number).to eq("122-555-1237")
      expect(transaction.billing_details.international_phone[:country_code]).to eq("1")
      expect(transaction.billing_details.international_phone[:national_number]).to eq("3121234567")
      expect(transaction.shipping_details.first_name).to eq("Andrew")
      expect(transaction.shipping_details.last_name).to eq("Mason")
      expect(transaction.shipping_details.company).to eq("Braintree")
      expect(transaction.shipping_details.street_address).to eq("456 W Main St")
      expect(transaction.shipping_details.extended_address).to eq("Apt 2F")
      expect(transaction.shipping_details.locality).to eq("Bartlett")
      expect(transaction.shipping_details.region).to eq("IL")
      expect(transaction.shipping_details.postal_code).to eq("60103")
      expect(transaction.shipping_details.country_name).to eq("United States of America")
      expect(transaction.shipping_details.country_code_alpha2).to eq("US")
      expect(transaction.shipping_details.country_code_alpha3).to eq("USA")
      expect(transaction.shipping_details.country_code_numeric).to eq("840")
      expect(transaction.shipping_details.phone_number).to eq("122-555-1236")
      expect(transaction.shipping_details.international_phone[:country_code]).to eq("1")
      expect(transaction.shipping_details.international_phone[:national_number]).to eq("3121234567")
    end

    it "allows merchant account to be specified" do
      result = Braintree::Transaction.sale(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )
      expect(result.success?).to eq(true)
      expect(result.transaction.merchant_account_id).to eq(SpecHelper::NonDefaultMerchantAccountId)
    end

    it "uses default merchant account when it is not specified" do
      result = Braintree::Transaction.sale(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )
      expect(result.success?).to eq(true)
      expect(result.transaction.merchant_account_id).to eq(SpecHelper::DefaultMerchantAccountId)
    end

    it "can store customer and credit card in the vault" do
      result = Braintree::Transaction.sale(
        :amount => "100",
        :customer => {
          :first_name => "Adam",
          :last_name => "Williams"
        },
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
        :options => {
          :store_in_vault => true
        },
      )
      expect(result.success?).to eq(true)
      transaction = result.transaction
      expect(transaction.customer_details.id).to match(/\A\d{6,}\z/)
      expect(transaction.vault_customer.id).to eq(transaction.customer_details.id)
      expect(transaction.credit_card_details.token).to match(/\A\w{4,}\z/)
      expect(transaction.vault_credit_card.token).to eq(transaction.credit_card_details.token)
    end

    it "associates a billing address with a credit card in the vault" do
      result = Braintree::Transaction.sale(
        :amount => "100",
        :customer => {
          :first_name => "Adam",
          :last_name => "Williams"
        },
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
        :billing => {
          :first_name => "Carl",
          :last_name => "Jones",
          :company => "Braintree",
          :street_address => "123 E Main St",
          :extended_address => "Suite 403",
          :locality => "Chicago",
          :region => "IL",
          :postal_code => "60622",
          :country_name => "United States of America"
        },
        :options => {
          :store_in_vault => true,
          :add_billing_address_to_payment_method => true,
        },
      )
      expect(result.success?).to eq(true)
      transaction = result.transaction
      expect(transaction.customer_details.id).to match(/\A\d{6,}\z/)
      expect(transaction.vault_customer.id).to eq(transaction.customer_details.id)
      credit_card = Braintree::CreditCard.find(transaction.vault_credit_card.token)
      expect(transaction.billing_details.id).to eq(credit_card.billing_address.id)
      expect(transaction.vault_billing_address.id).to eq(credit_card.billing_address.id)
      expect(credit_card.billing_address.first_name).to eq("Carl")
      expect(credit_card.billing_address.last_name).to eq("Jones")
      expect(credit_card.billing_address.company).to eq("Braintree")
      expect(credit_card.billing_address.street_address).to eq("123 E Main St")
      expect(credit_card.billing_address.extended_address).to eq("Suite 403")
      expect(credit_card.billing_address.locality).to eq("Chicago")
      expect(credit_card.billing_address.region).to eq("IL")
      expect(credit_card.billing_address.postal_code).to eq("60622")
      expect(credit_card.billing_address.country_name).to eq("United States of America")
    end

    it "can store the shipping address in the vault" do
      result = Braintree::Transaction.sale(
        :amount => "100",
        :customer => {
          :first_name => "Adam",
          :last_name => "Williams"
        },
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
        :shipping => {
          :first_name => "Carl",
          :last_name => "Jones",
          :company => "Braintree",
          :street_address => "123 E Main St",
          :extended_address => "Suite 403",
          :locality => "Chicago",
          :region => "IL",
          :postal_code => "60622",
          :country_name => "United States of America"
        },
        :options => {
          :store_in_vault => true,
          :store_shipping_address_in_vault => true,
        },
      )
      expect(result.success?).to eq(true)
      transaction = result.transaction
      expect(transaction.customer_details.id).to match(/\A\d{6,}\z/)
      expect(transaction.vault_customer.id).to eq(transaction.customer_details.id)
      expect(transaction.vault_shipping_address.id).to eq(transaction.vault_customer.addresses[0].id)
      shipping_address = transaction.vault_customer.addresses[0]
      expect(shipping_address.first_name).to eq("Carl")
      expect(shipping_address.last_name).to eq("Jones")
      expect(shipping_address.company).to eq("Braintree")
      expect(shipping_address.street_address).to eq("123 E Main St")
      expect(shipping_address.extended_address).to eq("Suite 403")
      expect(shipping_address.locality).to eq("Chicago")
      expect(shipping_address.region).to eq("IL")
      expect(shipping_address.postal_code).to eq("60622")
      expect(shipping_address.country_name).to eq("United States of America")
    end

    it "stores a unique number identifier in the vault" do
      result = Braintree::Transaction.sale(
        :amount => "100",
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
        :options => {:store_in_vault => true},
      )

      expect(result.success?).to eq(true)

      transaction = result.transaction
      expect(transaction.credit_card_details.unique_number_identifier).not_to be_nil
    end

    it "submits for settlement if given transaction[options][submit_for_settlement]" do
      result = Braintree::Transaction.sale(
        :amount => "100",
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
        :options => {
          :submit_for_settlement => true
        },
      )
      expect(result.success?).to eq(true)
      expect(result.transaction.status).to eq(Braintree::Transaction::Status::SubmittedForSettlement)
    end

    it "can specify the customer id and payment method token" do
      customer_id = "customer_#{rand(10**10)}"
      payment_method_token = "credit_card_#{rand(10**10)}"
      result = Braintree::Transaction.sale(
        :amount => "100",
        :customer => {
          :id => customer_id,
          :first_name => "Adam",
          :last_name => "Williams"
        },
        :credit_card => {
          :token => payment_method_token,
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
        :options => {
          :store_in_vault => true
        },
      )
      expect(result.success?).to eq(true)
      transaction = result.transaction
      expect(transaction.customer_details.id).to eq(customer_id)
      expect(transaction.vault_customer.id).to eq(customer_id)
      expect(transaction.credit_card_details.token).to eq(payment_method_token)
      expect(transaction.vault_credit_card.token).to eq(payment_method_token)
    end

    it "can specify existing shipping address" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        },
      )
      address = Braintree::Address.create!(
        :customer_id => customer.id,
        :street_address => "123 Fake St.",
      )
      result = Braintree::Transaction.sale(
        :amount => "100",
        :customer_id => customer.id,
        :shipping_address_id => address.id,
      )
      expect(result.success?).to eq(true)
      transaction = result.transaction
      expect(transaction.shipping_details.street_address).to eq("123 Fake St.")
      expect(transaction.customer_details.id).to eq(customer.id)
      expect(transaction.shipping_details.id).to eq(address.id)
    end

    it "returns an error result if validations fail" do
      params = {
        :transaction => {
          :amount => nil,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        }
      }
      result = Braintree::Transaction.sale(params[:transaction])
      expect(result.success?).to eq(false)
      expect(result.params).to eq({:transaction => {:type => "sale", :amount => nil, :credit_card => {:expiration_date => "05/2009"}}})
      expect(result.errors.for(:transaction).on(:amount)[0].code).to eq(Braintree::ErrorCodes::Transaction::AmountIsRequired)
    end

    it "validates currency_iso_code and creates transaction" do
      params = {
        :transaction => {
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :currency_iso_code => "USD",
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        }
      }
      result = Braintree::Transaction.sale(params[:transaction])
      expect(result.success?).to eq(true)
      result.transaction.currency_iso_code == "USD"
    end

    it "validates currency_iso_code and returns error" do
      params = {
        :transaction => {
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :currency_iso_code => "CAD",
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        }
      }
      result = Braintree::Transaction.sale(params[:transaction])
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:currency_iso_code)[0].code).to eq(Braintree::ErrorCodes::Transaction::CurrencyCodeNotSupportedByMerchantAccount)
    end

    it "validates currency_iso_code and creates transaction with specified merchant account" do
      params = {
        :transaction => {
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,
          :currency_iso_code => "USD",
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        }
      }
      result = Braintree::Transaction.sale(params[:transaction])
      expect(result.success?).to eq(true)
      result.transaction.currency_iso_code == "USD"
      result.transaction.merchant_account_id == SpecHelper::NonDefaultMerchantAccountId
    end

    it "validates currency_iso_code and returns error with specified merchant account" do
      params = {
        :transaction => {
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,
          :currency_iso_code => "CAD",
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        }
      }
      result = Braintree::Transaction.sale(params[:transaction])
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:currency_iso_code)[0].code).to eq(Braintree::ErrorCodes::Transaction::CurrencyCodeNotSupportedByMerchantAccount)
    end

    it "validates tax_amount for Aib domestic sweden transaction and returns error" do
      params = {
          :transaction => {
              :amount => Braintree::Test::TransactionAmounts::Authorize,
              :merchant_account_id => SpecHelper::AibSwedenMaMerchantAccountId,
              :credit_card => {
                  :number => Braintree::Test::CreditCardNumbers::Visa,
                  :expiration_date => "05/2030"
              }
          }
      }
      result = Braintree::Transaction.sale(params[:transaction])
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:tax_amount)[0].code).to eq(Braintree::ErrorCodes::Transaction::TaxAmountIsRequiredForAibSwedish)
    end

    it "skips advanced fraud checking if transaction[options][skip_advanced_fraud_checking] is set to true" do
      with_advanced_fraud_kount_integration_merchant do
        result = Braintree::Transaction.sale(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
          :options => {
            :skip_advanced_fraud_checking => true
          },
        )
        expect(result.success?).to eq(true)
        expect(result.transaction.risk_data).to be_nil
      end
    end

    it "works with Apple Pay params" do
      params = {
        :amount => "3.12",
        :apple_pay_card => {
          :number => "370295001292109",
          :cardholder_name => "JANE SMITH",
          :cryptogram => "AAAAAAAA/COBt84dnIEcwAA3gAAGhgEDoLABAAhAgAABAAAALnNCLw==",
          :expiration_month => "10",
          :expiration_year => "14",
          :eci_indicator => "07",
        }
      }
      result = Braintree::Transaction.sale(params)
      expect(result.success?).to eq(true)
      expect(result.transaction.status).to eq(Braintree::Transaction::Status::Authorized)
    end

    context "Google Pay params" do
      it "works with full params" do
        params = {
          :amount => "3.12",
          :google_pay_card => {
            :number => "4012888888881881",
            :cryptogram => "AAAAAAAA/COBt84dnIEcwAA3gAAGhgEDoLABAAhAgAABAAAALnNCLw==",
            :google_transaction_id => "25469d622c1dd37cb1a403c6d438e850",
            :expiration_month => "10",
            :expiration_year => "14",
            :source_card_type => "Visa",
            :source_card_last_four => "1111",
            :eci_indicator => "05",
          }
        }
        result = Braintree::Transaction.sale(params)
        expect(result.success?).to eq(true)
        expect(result.transaction.status).to eq(Braintree::Transaction::Status::Authorized)
      end

      it "works with only number, cryptogram, expiration and transaction ID (network tokenized card)" do
        params = {
          :amount => "3.12",
          :google_pay_card => {
            :number => "4012888888881881",
            :cryptogram => "AAAAAAAA/COBt84dnIEcwAA3gAAGhgEDoLABAAhAgAABAAAALnNCLw==",
            :google_transaction_id => "25469d622c1dd37cb1a403c6d438e850",
            :expiration_month => "10",
            :expiration_year => "14",
          }
        }
        result = Braintree::Transaction.sale(params)
        expect(result.success?).to eq(true)
        expect(result.transaction.status).to eq(Braintree::Transaction::Status::Authorized)
      end

      it "works with only number, expiration and transaction ID (non-tokenized card)" do
        params = {
          :amount => "3.12",
          :google_pay_card => {
            :number => "4012888888881881",
            :google_transaction_id => "25469d622c1dd37cb1a403c6d438e850",
            :expiration_month => "10",
            :expiration_year => "14",
          }
        }
        result = Braintree::Transaction.sale(params)
        expect(result.success?).to eq(true)
        expect(result.transaction.status).to eq(Braintree::Transaction::Status::Authorized)
      end
    end


    context "3rd party Card on File Network Token" do
      it "Works with all params" do
        params = {
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009",
            :network_tokenization_attributes => {
              :cryptogram => "/wAAAAAAAcb8AlGUF/1JQEkAAAA=",
              :ecommerce_indicator => "05",
              :token_requestor_id => "45310020105"
            },
          }
        }
        result = Braintree::Transaction.sale(params)
        expect(result.success?).to eq true
        expect(result.transaction.status).to eq Braintree::Transaction::Status::Authorized
        expect(result.transaction.processed_with_network_token?).to eq true

        network_token_details = result.transaction.network_token_details
        expect(network_token_details.is_network_tokenized?).to eq true
      end

      it "returns errors if validations on cryptogram fails" do
        params = {
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009",
            :network_tokenization_attributes => {
              :ecommerce_indicator => "05",
              :token_requestor_id => "45310020105"
            },
          }
        }
        result = Braintree::Transaction.sale(params)

        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).for(:credit_card).map { |e| e.code }.sort).to eq [Braintree::ErrorCodes::CreditCard::NetworkTokenizationAttributeCryptogramIsRequired]
      end
    end

    xit "Amex Pay with Points" do
      context "transaction creation" do
        it "succeeds when submit_for_settlement is true" do
          result = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :merchant_account_id => SpecHelper::FakeAmexDirectMerchantAccountId,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::AmexPayWithPoints::Success,
              :expiration_date => "05/2009"
            },
            :options => {
              :submit_for_settlement => true,
              :amex_rewards => {
                :request_id => "ABC123",
                :points => "1000",
                :currency_amount => "10.00",
                :currency_iso_code => "USD"
              }
            },
          )
          result.success?.should == true
          result.transaction.status.should == Braintree::Transaction::Status::SubmittedForSettlement
        end

        it "succeeds even if the card is ineligible" do
          result = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :merchant_account_id => SpecHelper::FakeAmexDirectMerchantAccountId,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::AmexPayWithPoints::IneligibleCard,
              :expiration_date => "05/2009"
            },
            :options => {
              :submit_for_settlement => true,
              :amex_rewards => {
                :request_id => "ABC123",
                :points => "1000",
                :currency_amount => "10.00",
                :currency_iso_code => "USD"
              }
            },
          )
          result.success?.should == true
          result.transaction.status.should == Braintree::Transaction::Status::SubmittedForSettlement
        end

        it "succeeds even if the card's balance is insufficient" do
          result = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :merchant_account_id => SpecHelper::FakeAmexDirectMerchantAccountId,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::AmexPayWithPoints::InsufficientPoints,
              :expiration_date => "05/2009"
            },
            :options => {
              :submit_for_settlement => true,
              :amex_rewards => {
                :request_id => "ABC123",
                :points => "1000",
                :currency_amount => "10.00",
                :currency_iso_code => "USD"
              }
            },
          )
          result.success?.should == true
          result.transaction.status.should == Braintree::Transaction::Status::SubmittedForSettlement
        end
      end

      context "submit for settlement" do
        it "succeeds" do
          result = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :merchant_account_id => SpecHelper::FakeAmexDirectMerchantAccountId,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::AmexPayWithPoints::Success,
              :expiration_date => "05/2009"
            },
            :options => {
              :amex_rewards => {
                :request_id => "ABC123",
                :points => "1000",
                :currency_amount => "10.00",
                :currency_iso_code => "USD"
              }
            },
          )
          result.success?.should == true

          result = Braintree::Transaction.submit_for_settlement(result.transaction.id)
          result.success?.should == true
          result.transaction.status.should == Braintree::Transaction::Status::SubmittedForSettlement
        end

        it "succeeds even if the card is ineligible" do
          result = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :merchant_account_id => SpecHelper::FakeAmexDirectMerchantAccountId,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::AmexPayWithPoints::IneligibleCard,
              :expiration_date => "05/2009"
            },
            :options => {
              :amex_rewards => {
                :request_id => "ABC123",
                :points => "1000",
                :currency_amount => "10.00",
                :currency_iso_code => "USD"
              }
            },
          )
          result.success?.should == true
          result.transaction.status.should == Braintree::Transaction::Status::Authorized

          result = Braintree::Transaction.submit_for_settlement(result.transaction.id)
          result.success?.should == true
          result.transaction.status.should == Braintree::Transaction::Status::SubmittedForSettlement
        end

        it "succeeds even if the card's balance is insufficient" do
          result = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :merchant_account_id => SpecHelper::FakeAmexDirectMerchantAccountId,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::AmexPayWithPoints::IneligibleCard,
              :expiration_date => "05/2009"
            },
            :options => {
              :amex_rewards => {
                :request_id => "ABC123",
                :points => "1000",
                :currency_amount => "10.00",
                :currency_iso_code => "USD"
              }
            },
          )
          result.success?.should == true
          result.transaction.status.should == Braintree::Transaction::Status::Authorized

          result = Braintree::Transaction.submit_for_settlement(result.transaction.id)
          result.success?.should == true
          result.transaction.status.should == Braintree::Transaction::Status::SubmittedForSettlement
        end
      end
    end

    context "Pinless debit transaction" do
      it "succesfully submits for settlement" do
        result = Braintree::Transaction.sale(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :merchant_account_id => SpecHelper::PinlessDebitMerchantAccountId,
          :currency_iso_code => "USD",
          :payment_method_nonce => Braintree::Test::Nonce::TransactablePinlessDebitVisa,
          :options => {
            :submit_for_settlement => true
          },
        )
        expect(result.success?).to be_truthy
        expect(result.transaction.debit_network).not_to be_nil
      end
    end

    context "Process debit as credit" do
      it "succesfully completed pinless eligible transaction in signature" do
        result = Braintree::Transaction.sale(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :merchant_account_id => SpecHelper::PinlessDebitMerchantAccountId,
          :currency_iso_code => "USD",
          :payment_method_nonce => Braintree::Test::Nonce::TransactablePinlessDebitVisa,
          :options => {
            :submit_for_settlement => true,
            :credit_card => {
              :process_debit_as_credit => true
            }
          },
        )
        expect(result.success?).to be_truthy
        expect(result.transaction.debit_network).to be_nil
      end
    end
  end

  describe "self.sale!" do
    it "returns the transaction if valid" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )
      expect(transaction.id).to match(/^\w{6,}$/)
      expect(transaction.type).to eq("sale")
      expect(transaction.amount).to eq(BigDecimal(Braintree::Test::TransactionAmounts::Authorize))
      expect(transaction.credit_card_details.bin).to eq(Braintree::Test::CreditCardNumbers::Visa[0, 6])
      expect(transaction.credit_card_details.last_4).to eq(Braintree::Test::CreditCardNumbers::Visa[-4..-1])
      expect(transaction.credit_card_details.expiration_date).to eq("05/2009")
    end

    it "raises a ValidationsFailed if invalid" do
      expect do
        Braintree::Transaction.sale!(
          :amount => nil,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
        )
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.submit_for_settlement" do
    it "returns a successful result if successful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        },
      )
      result = Braintree::Transaction.submit_for_settlement(transaction.id)
      expect(result.success?).to eq(true)
    end

    it "can submit a specific amount for settlement" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        },
      )
      expect(transaction.amount).to eq(BigDecimal("1000.00"))
      result = Braintree::Transaction.submit_for_settlement(transaction.id, "999.99")
      expect(result.success?).to eq(true)
      expect(result.transaction.amount).to eq(BigDecimal("999.99"))
      expect(result.transaction.status).to eq(Braintree::Transaction::Status::SubmittedForSettlement)
      expect(result.transaction.updated_at.between?(Time.now - 60, Time.now)).to eq(true)
    end

    it "returns a successful result if order_id is passed in as an options hash" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        },
      )
      options = {:order_id => "ABC123"}
      result = Braintree::Transaction.submit_for_settlement(transaction.id, nil, options)
      expect(result.success?).to eq(true)
      expect(result.transaction.order_id).to eq("ABC123")
      expect(result.transaction.status).to eq(Braintree::Transaction::Status::SubmittedForSettlement)
    end

    it "returns a successful result if descritpors are passed in as an options hash" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        },
      )

      options = {
        :descriptor => {
          :name => "123*123456789012345678",
          :phone => "3334445555",
          :url => "ebay.com"
        }
      }

      result = Braintree::Transaction.submit_for_settlement(transaction.id, nil, options)
      expect(result.success?).to eq(true)
      expect(result.transaction.status).to eq(Braintree::Transaction::Status::SubmittedForSettlement)
      expect(result.transaction.descriptor.name).to eq("123*123456789012345678")
      expect(result.transaction.descriptor.phone).to eq("3334445555")
      expect(result.transaction.descriptor.url).to eq("ebay.com")
    end

    it "raises an error if an invalid option is passed in" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        },
      )

      options = {:order_id => "ABC123", :invalid_option => "i'm invalid"}

      expect do
        Braintree::Transaction.submit_for_settlement(transaction.id, nil, options)
      end.to raise_error(ArgumentError)
    end

    it "returns an error result if settlement is too large" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::CardProcessorBRLMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        },
      )
      expect(transaction.amount).to eq(BigDecimal("1000.00"))
      result = Braintree::Transaction.submit_for_settlement(transaction.id, "1000.01")
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:amount)[0].code).to eq(Braintree::ErrorCodes::Transaction::SettlementAmountIsTooLarge)
      expect(result.params[:transaction][:amount]).to eq("1000.01")
    end

    it "returns an error result if status is not authorized" do
      transaction = Braintree::Transaction.sale(
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        },
      ).transaction
      result = Braintree::Transaction.submit_for_settlement(transaction.id)
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:base)[0].code).to eq(Braintree::ErrorCodes::Transaction::CannotSubmitForSettlement)
    end

    context "service fees" do
      it "returns an error result if amount submitted for settlement is less than service fee amount" do
        transaction = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :merchant_account_id => SpecHelper::NonDefaultSubMerchantAccountId,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "06/2009"
          },
          :service_fee_amount => "1.00",
        ).transaction
        result = Braintree::Transaction.submit_for_settlement(transaction.id, "0.01")
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).on(:amount)[0].code).to eq(Braintree::ErrorCodes::Transaction::SettlementAmountIsLessThanServiceFeeAmount)
      end
    end

    it "succeeds when industry data is provided" do
      transaction = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
        :options => {
          :submit_for_settlement => false
        },
      ).transaction

      result = Braintree::Transaction.submit_for_settlement(transaction.id, Braintree::Test::TransactionAmounts::Authorize, industry_data_flight_params)
      expect(result.success?).to be_truthy
    end

    it "returns errors if validations on industry data fails" do
      transaction = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
        :options => {
          :submit_for_settlement => false
        },
      ).transaction

      options = {
        :industry => {
          :industry_type => Braintree::Transaction::IndustryType::TravelAndFlight,
          :data => {
            :fare_amount => -1_23,
            :restricted_ticket => false,
            :legs => [
              {
                :fare_amount => -1_23
              }
            ]
          }
        },
      }

      result = Braintree::Transaction.submit_for_settlement(transaction.id, Braintree::Test::TransactionAmounts::Authorize, options)
      expect(result.success?).to be_falsey
      industry_errors = result.errors.for(:transaction).for(:industry).map { |e| e.code }.sort
      expect(industry_errors).to eq([Braintree::ErrorCodes::Transaction::Industry::TravelFlight::FareAmountCannotBeNegative])

      leg_errors = result.errors.for(:transaction).for(:industry).for(:legs).for(:index_0).map { |e| e.code }.sort
      expect(leg_errors).to eq([Braintree::ErrorCodes::Transaction::Industry::Leg::TravelFlight::FareAmountCannotBeNegative])
    end

    xit "succeeds when level 2 data is provided" do
      result = Braintree::Transaction.sale(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::FakeAmexDirectMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::AmexPayWithPoints::Success,
          :expiration_date => "05/2009"
        },
        :options => {
          :amex_rewards => {
            :request_id => "ABC123",
            :points => "1000",
            :currency_amount => "10.00",
            :currency_iso_code => "USD"
          }
        },
      )
      expect(result.success?).to eq(true)

      result = Braintree::Transaction.submit_for_settlement(result.transaction.id, nil, :tax_amount => "2.00", :tax_exempt => false, :purchase_order_number => "0Rd3r#")
      expect(result.success?).to eq(true)
      expect(result.transaction.status).to eq(Braintree::Transaction::Status::SubmittedForSettlement)
    end

    xit "succeeds when level 3 data is provided" do
      result = Braintree::Transaction.sale(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::FakeAmexDirectMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::AmexPayWithPoints::Success,
          :expiration_date => "05/2009"
        },
        :options => {
          :amex_rewards => {
            :request_id => "ABC123",
            :points => "1000",
            :currency_amount => "10.00",
            :currency_iso_code => "USD"
          }
        },
      )
      expect(result.success?).to eq(true)

      result = Braintree::Transaction.submit_for_settlement(
        result.transaction.id,
        nil,
        :discount_amount => "2.00",
        :shipping_amount => "1.23",
        :ships_from_postal_code => "90210",
        :line_items => [
          {
            :quantity => 1,
            :unit_amount => 1,
            :name => "New line item",
            :kind => "debit",
            :total_amount => "18.00",
            :discount_amount => "12.00",
            :tax_amount => "0",
          },
        ],
      )
      expect(result.success?).to eq(true)
      expect(result.transaction.status).to eq(Braintree::Transaction::Status::SubmittedForSettlement)
    end
  end

  describe "self.submit_for_settlement!" do
    it "returns the transaction if successful" do
      original_transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        },
      )
      options = {:order_id => "ABC123"}
      transaction = Braintree::Transaction.submit_for_settlement!(original_transaction.id, "0.01", options)
      expect(transaction.status).to eq(Braintree::Transaction::Status::SubmittedForSettlement)
      expect(transaction.id).to eq(original_transaction.id)
      expect(transaction.order_id).to eq(options[:order_id])
    end

    it "raises a ValidationsFailed if unsuccessful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::CardProcessorBRLMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        },
      )
      expect(transaction.amount).to eq(BigDecimal("1000.00"))
      expect do
        Braintree::Transaction.submit_for_settlement!(transaction.id, "1000.01")
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "update details" do
    context "when status is submitted_for_settlement" do
      let(:transaction) do
        Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :merchant_account_id => SpecHelper::DefaultMerchantAccountId,
          :descriptor => {
            :name => "123*123456789012345678",
            :phone => "3334445555",
            :url => "ebay.com"
          },
          :order_id => "123",
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "06/2009"
          },
          :options => {
            :submit_for_settlement => true
          },
        )
      end

      it "successfully updates details" do
        result = Braintree::Transaction.update_details(transaction.id, {
          :amount => Braintree::Test::TransactionAmounts::Authorize.to_f - 1,
          :descriptor => {
            :name => "456*123456789012345678",
            :phone => "3334445555",
            :url => "ebay.com",
          },
          :order_id => "456"
        })
        expect(result.success?).to eq(true)
        expect(result.transaction.amount).to eq(BigDecimal(Braintree::Test::TransactionAmounts::Authorize) - 1)
        expect(result.transaction.order_id).to eq("456")
        expect(result.transaction.descriptor.name).to eq("456*123456789012345678")
      end

      it "raises an error when a key is invalid" do
        expect do
          Braintree::Transaction.update_details(transaction.id, {
            :invalid_key => Braintree::Test::TransactionAmounts::Authorize.to_f - 1,
            :descriptor => {
              :name => "456*123456789012345678",
              :phone => "3334445555",
              :url => "ebay.com",
            },
            :order_id => "456"
          })
        end.to raise_error(ArgumentError)
      end

      describe "errors" do
        it "returns an error response when the settlement amount is invalid" do
          result = Braintree::Transaction.update_details(transaction.id, {
            :amount => "10000",
            :descriptor => {
              :name => "456*123456789012345678",
              :phone => "3334445555",
              :url => "ebay.com",
            },
            :order_id => "456"
          })
          expect(result.success?).to eq(false)
          expect(result.errors.for(:transaction).on(:amount)[0].code).to eq(Braintree::ErrorCodes::Transaction::SettlementAmountIsTooLarge)
        end

        it "returns an error response when the descriptor is invalid" do
          result = Braintree::Transaction.update_details(transaction.id, {
            :amount => Braintree::Test::TransactionAmounts::Authorize.to_f - 1,
            :descriptor => {
              :name => "invalid descriptor name",
              :phone => "invalid phone",
              :url => "12345678901234"
            },
            :order_id => "456"
          })
          expect(result.success?).to eq(false)
          expect(result.errors.for(:transaction).for(:descriptor).on(:name)[0].code).to eq(Braintree::ErrorCodes::Descriptor::NameFormatIsInvalid)
          expect(result.errors.for(:transaction).for(:descriptor).on(:phone)[0].code).to eq(Braintree::ErrorCodes::Descriptor::PhoneFormatIsInvalid)
          expect(result.errors.for(:transaction).for(:descriptor).on(:url)[0].code).to eq(Braintree::ErrorCodes::Descriptor::UrlFormatIsInvalid)
        end

        it "returns an error response when the order_id is invalid" do
          result = Braintree::Transaction.update_details(transaction.id, {
            :amount => Braintree::Test::TransactionAmounts::Authorize.to_f - 1,
            :descriptor => {
              :name => "456*123456789012345678",
              :phone => "3334445555",
              :url => "ebay.com",
            },
            :order_id => "x" * 256
          })
          expect(result.success?).to eq(false)
          expect(result.errors.for(:transaction).on(:order_id)[0].code).to eq(Braintree::ErrorCodes::Transaction::OrderIdIsTooLong)
        end

        it "returns an error on an unsupported processor" do
          transaction = Braintree::Transaction.sale!(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :merchant_account_id => SpecHelper::FakeAmexDirectMerchantAccountId,
            :descriptor => {
              :name => "123*123456789012345678",
              :phone => "3334445555",
              :url => "ebay.com"
            },
            :order_id => "123",
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::AmexPayWithPoints::Success,
              :expiration_date => "05/2009"
            },
            :options => {
              :submit_for_settlement => true
            },
          )
          result = Braintree::Transaction.update_details(transaction.id, {
            :amount => Braintree::Test::TransactionAmounts::Authorize.to_f - 1,
            :descriptor => {
              :name => "456*123456789012345678",
              :phone => "3334445555",
              :url => "ebay.com",
            },
            :order_id => "456"
          })
          expect(result.success?).to eq(false)
          expect(result.errors.for(:transaction).on(:base)[0].code).to eq(Braintree::ErrorCodes::Transaction::ProcessorDoesNotSupportUpdatingTransactionDetails)
        end
      end
    end

    context "when status is not submitted_for_settlement" do
      it "returns an error" do
        transaction = Braintree::Transaction.sale!(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :merchant_account_id => SpecHelper::DefaultMerchantAccountId,
          :descriptor => {
            :name => "123*123456789012345678",
            :phone => "3334445555",
            :url => "ebay.com"
          },
          :order_id => "123",
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "06/2009"
          },
        )
        result = Braintree::Transaction.update_details(transaction.id, {
          :amount => Braintree::Test::TransactionAmounts::Authorize.to_f - 1,
          :descriptor => {
            :name => "456*123456789012345678",
            :phone => "3334445555",
            :url => "ebay.com",
          },
          :order_id => "456"
        })
        expect(result.success?).to eq(false)
        expect(result.errors.for(:transaction).on(:base)[0].code).to eq(Braintree::ErrorCodes::Transaction::CannotUpdateTransactionDetailsNotSubmittedForSettlement)
      end
    end

  end

  describe "submit for partial settlement" do
    it "successfully submits multiple times for partial settlement" do
      authorized_transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::DefaultMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        },
      )

      result = Braintree::Transaction.submit_for_partial_settlement(authorized_transaction.id, 100)
      expect(result.success?).to eq(true)
      partial_settlement_transaction1 = result.transaction
      expect(partial_settlement_transaction1.amount).to eq(100)
      expect(partial_settlement_transaction1.type).to eq(Braintree::Transaction::Type::Sale)
      expect(partial_settlement_transaction1.status).to eq(Braintree::Transaction::Status::SubmittedForSettlement)
      expect(partial_settlement_transaction1.authorized_transaction_id).to eq(authorized_transaction.id)

      refreshed_authorized_transaction = Braintree::Transaction.find(authorized_transaction.id)
      expect(refreshed_authorized_transaction.status).to eq(Braintree::Transaction::Status::SettlementPending)
      expect(refreshed_authorized_transaction.partial_settlement_transaction_ids).to eq([partial_settlement_transaction1.id])

      result = Braintree::Transaction.submit_for_partial_settlement(authorized_transaction.id, 800)
      expect(result.success?).to eq(true)
      partial_settlement_transaction2 = result.transaction
      expect(partial_settlement_transaction2.amount).to eq(800)
      expect(partial_settlement_transaction2.type).to eq(Braintree::Transaction::Type::Sale)
      expect(partial_settlement_transaction2.status).to eq(Braintree::Transaction::Status::SubmittedForSettlement)
      expect(partial_settlement_transaction2.authorized_transaction_id).to eq(authorized_transaction.id)

      refreshed_authorized_transaction = Braintree::Transaction.find(authorized_transaction.id)
      expect(refreshed_authorized_transaction.status).to eq(Braintree::Transaction::Status::SettlementPending)
      expect(refreshed_authorized_transaction.partial_settlement_transaction_ids.sort).to eq([partial_settlement_transaction1.id, partial_settlement_transaction2.id].sort)
    end

    it "allows partial settlement to be submitted with order_id" do
      authorized_transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::DefaultMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )

      result = Braintree::Transaction.submit_for_partial_settlement(authorized_transaction.id, 100, :order_id => 1234)
      expect(result.success?).to eq(true)
      partial_settlement_transaction = result.transaction
      expect(partial_settlement_transaction.order_id).to eq("1234")
    end

    it "returns an error with an order_id that's too long" do
      authorized_transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::DefaultMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )

      result = Braintree::Transaction.submit_for_partial_settlement(authorized_transaction.id, 100, :order_id => "1"*256)
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:order_id)[0].code).to eq(Braintree::ErrorCodes::Transaction::OrderIdIsTooLong)
    end

    it "allows partial settlement to be submitted with descriptors" do
      authorized_transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::DefaultMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )

      result = Braintree::Transaction.submit_for_partial_settlement(
        authorized_transaction.id,
        100,
        :descriptor => {:name => "123*123456789012345678", :phone => "5555551234", :url => "url.com"},
      )
      expect(result.success?).to eq(true)
      partial_settlement_transaction = result.transaction
      expect(partial_settlement_transaction.descriptor.name).to eq("123*123456789012345678")
      expect(partial_settlement_transaction.descriptor.phone).to eq("5555551234")
      expect(partial_settlement_transaction.descriptor.url).to eq("url.com")
    end

    it "returns an error with a descriptor in an invalid format" do
      authorized_transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::DefaultMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )

      result = Braintree::Transaction.submit_for_partial_settlement(
        authorized_transaction.id,
        100,
        :descriptor => {
          :name => "invalid_format",
          :phone => "%bad4445555",
          :url => "12345678901234"
        },
      )
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).for(:descriptor).on(:name)[0].code).to eq(Braintree::ErrorCodes::Descriptor::NameFormatIsInvalid)
      expect(result.errors.for(:transaction).for(:descriptor).on(:phone)[0].code).to eq(Braintree::ErrorCodes::Descriptor::PhoneFormatIsInvalid)
      expect(result.errors.for(:transaction).for(:descriptor).on(:url)[0].code).to eq(Braintree::ErrorCodes::Descriptor::UrlFormatIsInvalid)
    end

    it "returns an error with an unsupported processor" do
      authorized_transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::FakeAmexDirectMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::AmexPayWithPoints::Success,
          :expiration_date => "05/2009"
        },
      )

      result = Braintree::Transaction.submit_for_partial_settlement(authorized_transaction.id, 100)
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:base)[0].code).to eq(Braintree::ErrorCodes::Transaction::ProcessorDoesNotSupportPartialSettlement)
    end

    it "returns an error with an invalid payment instrument type" do
      authorized_transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::FakeVenmoAccountMerchantAccountId,
        :payment_method_nonce => Braintree::Test::Nonce::VenmoAccount,
      )

      result = Braintree::Transaction.submit_for_partial_settlement(authorized_transaction.id, 100)
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:base)[0].code).to eq(Braintree::ErrorCodes::Transaction::PaymentInstrumentTypeIsNotAccepted)
    end

    it "returns an error result if settlement amount greater than authorized amount" do
      authorized_transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::DefaultMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        },
      )

      result = Braintree::Transaction.submit_for_partial_settlement(authorized_transaction.id, 100)
      expect(result.success?).to eq(true)

      result = Braintree::Transaction.submit_for_partial_settlement(authorized_transaction.id, 901)
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:amount)[0].code).to eq(Braintree::ErrorCodes::Transaction::SettlementAmountIsTooLarge)
    end

    it "returns an error result if status is not authorized" do
      authorized_transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::DefaultMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        },
      )

      result = Braintree::Transaction.void(authorized_transaction.id)
      expect(result.success?).to eq(true)

      result = Braintree::Transaction.submit_for_partial_settlement(authorized_transaction.id, 100)
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:base)[0].code).to eq(Braintree::ErrorCodes::Transaction::CannotSubmitForSettlement)
    end

    it "succeeds when industry data is provided" do
      transaction = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
        :options => {
          :submit_for_settlement => false
        },
      ).transaction

      result = Braintree::Transaction.submit_for_partial_settlement(transaction.id, Braintree::Test::TransactionAmounts::Authorize, industry_data_flight_params)
      expect(result.success?).to be_truthy
    end

    it "final_capture indicates the current partial_capture as final" do
      authorized_transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::DefaultMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        },
      )

      result1 = Braintree::Transaction.submit_for_partial_settlement(authorized_transaction.id, 100)
      expect(result1.success?).to eq(true)
      partial_settlement_transaction1 = result1.transaction
      expect(partial_settlement_transaction1.amount).to eq(100)
      expect(partial_settlement_transaction1.type).to eq(Braintree::Transaction::Type::Sale)
      expect(partial_settlement_transaction1.status).to eq(Braintree::Transaction::Status::SubmittedForSettlement)
      expect(partial_settlement_transaction1.authorized_transaction_id).to eq(authorized_transaction.id)
      refreshed_authorized_transaction1 = Braintree::Transaction.find(authorized_transaction.id)
      expect(refreshed_authorized_transaction1.status).to eq(Braintree::Transaction::Status::SettlementPending)

      options = {:final_capture => true}
      result2 = Braintree::Transaction.submit_for_partial_settlement(authorized_transaction.id, 100, options)
      expect(result2.success?).to eq(true)
      partial_settlement_transaction2 = result2.transaction
      expect(partial_settlement_transaction2.amount).to eq(100)
      expect(partial_settlement_transaction2.type).to eq(Braintree::Transaction::Type::Sale)
      expect(partial_settlement_transaction2.status).to eq(Braintree::Transaction::Status::SubmittedForSettlement)
      expect(partial_settlement_transaction2.authorized_transaction_id).to eq(authorized_transaction.id)

      refreshed_authorized_transaction2 = Braintree::Transaction.find(authorized_transaction.id)
      expect(refreshed_authorized_transaction2.status).to eq(Braintree::Transaction::Status::SettlementPending)
    end
  end

  describe "self.submit_for_partial_settlement!" do
    it "returns the transaction if successful" do
      original_transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        },
      )
      options = {:order_id => "ABC123"}
      transaction = Braintree::Transaction.submit_for_partial_settlement!(original_transaction.id, "0.01", options)
      expect(transaction.status).to eq(Braintree::Transaction::Status::SubmittedForSettlement)
      expect(transaction.order_id).to eq(options[:order_id])
    end

    it "raises a ValidationsFailed if unsuccessful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        },
      )
      expect(transaction.amount).to eq(BigDecimal("1000.00"))
      expect do
        Braintree::Transaction.submit_for_partial_settlement!(transaction.id, "1000.01")
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.release_from_escrow" do
    it "returns the transaction if successful" do
      original_transaction = create_escrowed_transcation

      result = Braintree::Transaction.release_from_escrow(original_transaction.id)
      expect(result.transaction.escrow_status).to eq(Braintree::Transaction::EscrowStatus::ReleasePending)
    end

    it "returns an error result if escrow_status is not HeldForEscrow" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::NonDefaultSubMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
        :service_fee_amount => "1.00",
      )

      expect(transaction.escrow_status).to be_nil

      result = Braintree::Transaction.release_from_escrow(transaction.id)
      expect(result.errors.for(:transaction).on(:base)[0].code).to eq(Braintree::ErrorCodes::Transaction::CannotReleaseFromEscrow)
    end
  end

  describe "self.release_from_escrow!" do
    it "returns the transaction when successful" do
      original_transaction = create_escrowed_transcation

      transaction = Braintree::Transaction.release_from_escrow!(original_transaction.id)
      expect(transaction.escrow_status).to eq(Braintree::Transaction::EscrowStatus::ReleasePending)
    end

    it "raises an error when transaction is not successful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::NonDefaultSubMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
        :service_fee_amount => "1.00",
      )

      expect(transaction.escrow_status).to be_nil

      expect do
        Braintree::Transaction.release_from_escrow!(transaction.id)
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.cancel_release" do
    it "returns the transaction if successful" do
      transaction = create_escrowed_transcation
      result = Braintree::Transaction.release_from_escrow(transaction.id)
      expect(result.transaction.escrow_status).to eq(Braintree::Transaction::EscrowStatus::ReleasePending)

      result = Braintree::Transaction.cancel_release(transaction.id)

      expect(result.success?).to be(true)
      expect(result.transaction.escrow_status).to eq(Braintree::Transaction::EscrowStatus::Held)
    end

    it "returns an error result if escrow_status is not ReleasePending" do
      transaction = create_escrowed_transcation

      result = Braintree::Transaction.cancel_release(transaction.id)

      expect(result.success?).to be(false)
      expect(result.errors.for(:transaction).on(:base)[0].code).to eq(Braintree::ErrorCodes::Transaction::CannotCancelRelease)
    end
  end

  describe "self.cancel_release!" do
    it "returns the transaction when release is cancelled" do
      transaction = create_escrowed_transcation
      result = Braintree::Transaction.release_from_escrow(transaction.id)
      expect(result.transaction.escrow_status).to eq(Braintree::Transaction::EscrowStatus::ReleasePending)

      transaction = Braintree::Transaction.cancel_release!(transaction.id)

      expect(transaction.escrow_status).to eq(Braintree::Transaction::EscrowStatus::Held)
    end

    it "raises an error when release cannot be cancelled" do
      transaction = create_escrowed_transcation

      expect {
        transaction = Braintree::Transaction.cancel_release!(transaction.id)
      }.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.credit" do
    it "returns a successful result with type=credit if successful" do
      result = Braintree::Transaction.credit(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )
      expect(result.success?).to eq(true)
      expect(result.transaction.id).to match(/^\w{6,}$/)
      expect(result.transaction.type).to eq("credit")
      expect(result.transaction.amount).to eq(BigDecimal(Braintree::Test::TransactionAmounts::Authorize))
      expect(result.transaction.credit_card_details.bin).to eq(Braintree::Test::CreditCardNumbers::Visa[0, 6])
      expect(result.transaction.credit_card_details.last_4).to eq(Braintree::Test::CreditCardNumbers::Visa[-4..-1])
      expect(result.transaction.credit_card_details.expiration_date).to eq("05/2009")
    end

    it "returns an error result if validations fail" do
      params = {
        :transaction => {
          :amount => nil,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        }
      }
      result = Braintree::Transaction.credit(params[:transaction])
      expect(result.success?).to eq(false)
      expect(result.params).to eq({:transaction => {:type => "credit", :amount => nil, :credit_card => {:expiration_date => "05/2009"}}})
      expect(result.errors.for(:transaction).on(:amount)[0].code).to eq(Braintree::ErrorCodes::Transaction::AmountIsRequired)
    end

    it "allows merchant account to be specified" do
      result = Braintree::Transaction.credit(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )
      expect(result.success?).to eq(true)
      expect(result.transaction.merchant_account_id).to eq(SpecHelper::NonDefaultMerchantAccountId)
    end

    it "uses default merchant account when it is not specified" do
      result = Braintree::Transaction.credit(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )
      expect(result.success?).to eq(true)
      expect(result.transaction.merchant_account_id).to eq(SpecHelper::DefaultMerchantAccountId)
    end

    it "disallows service fee on a credit" do
      params = {
        :transaction => {
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
          :service_fee_amount => "1.00"
        }
      }
      result = Braintree::Transaction.credit(params[:transaction])
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:base).map(&:code)).to include(Braintree::ErrorCodes::Transaction::ServiceFeeIsNotAllowedOnCredits)
    end
  end

  describe "self.credit!" do
    it "returns the transaction if valid" do
      transaction = Braintree::Transaction.credit!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )
      expect(transaction.id).to match(/^\w{6,}$/)
      expect(transaction.type).to eq("credit")
      expect(transaction.amount).to eq(BigDecimal(Braintree::Test::TransactionAmounts::Authorize))
      expect(transaction.credit_card_details.bin).to eq(Braintree::Test::CreditCardNumbers::Visa[0, 6])
      expect(transaction.credit_card_details.last_4).to eq(Braintree::Test::CreditCardNumbers::Visa[-4..-1])
      expect(transaction.credit_card_details.expiration_date).to eq("05/2009")
    end

    it "raises a ValidationsFailed if invalid" do
      expect do
        Braintree::Transaction.credit!(
          :amount => nil,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
        )
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.find" do
    it "finds the transaction with the given id" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )
      expect(result.success?).to eq(true)
      created_transaction = result.transaction
      found_transaction = Braintree::Transaction.find(created_transaction.id)
      expect(found_transaction).to eq(created_transaction)
      expect(found_transaction.graphql_id).not_to be_nil
    end

    it "finds the vaulted transaction with the given id" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
        :options => {:store_in_vault => true},
      )
      expect(result.success?).to eq(true)
      created_transaction = result.transaction
      found_transaction = Braintree::Transaction.find(created_transaction.id)
      expect(found_transaction).to eq(created_transaction)

      expect(found_transaction.credit_card_details.unique_number_identifier).not_to be_nil
    end

    it "raises a NotFoundError exception if transaction cannot be found" do
      expect do
        Braintree::Transaction.find("invalid-id")
      end.to raise_error(Braintree::NotFoundError, 'transaction with id "invalid-id" not found')
    end

    it "finds a transaction and returns an acquirer_reference_number if the transaction has one" do
      transaction = Braintree::Transaction.find("transactionwithacquirerreferencenumber")

      expect(transaction.acquirer_reference_number).to eq("123456789 091019")
    end

    context "disbursement_details" do
      it "includes disbursement_details on found transactions" do
        found_transaction = Braintree::Transaction.find("deposittransaction")

        expect(found_transaction.disbursed?).to eq(true)
        disbursement = found_transaction.disbursement_details

        expect(disbursement.disbursement_date).to be_a Date
        expect(disbursement.disbursement_date).to eq Date.parse("2013-04-10")
        expect(disbursement.settlement_amount).to eq("100.00")
        expect(disbursement.settlement_currency_iso_code).to eq("USD")
        expect(disbursement.settlement_currency_exchange_rate).to eq("1")
        expect(disbursement.funds_held?).to eq(false)
        expect(disbursement.success?).to be(true)
      end

      it "is not disbursed" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
        )
        expect(result.success?).to eq(true)
        created_transaction = result.transaction

        expect(created_transaction.disbursed?).to eq(false)
      end
    end

    context "disputes" do
      it "includes disputes on found transactions" do
        found_transaction = Braintree::Transaction.find("disputedtransaction")

        expect(found_transaction.disputes.count).to eq(1)

        dispute = found_transaction.disputes.first
        expect(dispute.received_date).to eq(Date.new(2014, 3, 1))
        expect(dispute.reply_by_date).to eq(Date.new(2014, 3, 21))
        expect(dispute.amount).to eq(Braintree::Util.to_big_decimal("250.00"))
        expect(dispute.currency_iso_code).to eq("USD")
        expect(dispute.reason).to eq(Braintree::Dispute::Reason::Fraud)
        expect(dispute.status).to eq(Braintree::Dispute::Status::Won)
        expect(dispute.transaction_details.amount).to eq(Braintree::Util.to_big_decimal("1000.00"))
        expect(dispute.transaction_details.id).to eq("disputedtransaction")
        expect(dispute.kind).to eq(Braintree::Dispute::Kind::Chargeback)
        expect(dispute.date_opened).to eq(Date.new(2014, 3, 1))
        expect(dispute.date_won).to eq(Date.new(2014, 3, 7))
      end

      it "includes disputes on found transactions" do
        found_transaction = Braintree::Transaction.find("retrievaltransaction")

        expect(found_transaction.disputes.count).to eq(1)

        dispute = found_transaction.disputes.first
        expect(dispute.amount).to eq(Braintree::Util.to_big_decimal("1000.00"))
        expect(dispute.currency_iso_code).to eq("USD")
        expect(dispute.reason).to eq(Braintree::Dispute::Reason::Retrieval)
        expect(dispute.status).to eq(Braintree::Dispute::Status::Open)
        expect(dispute.transaction_details.amount).to eq(Braintree::Util.to_big_decimal("1000.00"))
        expect(dispute.transaction_details.id).to eq("retrievaltransaction")
      end

      it "is not disputed" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
        )
        expect(result.success?).to eq(true)
        created_transaction = result.transaction

        expect(created_transaction.disputes).to eq([])
      end
    end

    context "three_d_secure_info" do
      it "returns all the three_d_secure_info" do
        transaction = Braintree::Transaction.find("threedsecuredtransaction")

        expect(transaction.three_d_secure_info.authentication).to have_key(:trans_status)
        expect(transaction.three_d_secure_info.authentication).to have_key(:trans_status_reason)
        expect(transaction.three_d_secure_info.lookup).to have_key(:trans_status)
        expect(transaction.three_d_secure_info.lookup).to have_key(:trans_status_reason)
        expect(transaction.three_d_secure_info.cavv).to eq("somebase64value")
        expect(transaction.three_d_secure_info.ds_transaction_id).to eq("dstxnid")
        expect(transaction.three_d_secure_info.eci_flag).to eq("07")
        expect(transaction.three_d_secure_info.enrolled).to eq("Y")
        expect(transaction.three_d_secure_info.pares_status).to eq("Y")
        expect(transaction.three_d_secure_info).to be_liability_shift_possible
        expect(transaction.three_d_secure_info).to be_liability_shifted
        expect(transaction.three_d_secure_info.status).to eq("authenticate_successful")
        expect(transaction.three_d_secure_info.three_d_secure_authentication_id).to be
        expect(transaction.three_d_secure_info.three_d_secure_version).not_to be_nil
        expect(transaction.three_d_secure_info.xid).to eq("xidvalue")
      end

      it "is nil if the transaction wasn't 3d secured" do
        transaction = Braintree::Transaction.find("settledtransaction")

        expect(transaction.three_d_secure_info).to be_nil
      end
    end

    context "paypal" do
      it "returns all the required paypal fields" do
        transaction = Braintree::Transaction.find("settledtransaction")

        expect(transaction.paypal_details.debug_id).not_to be_nil
        expect(transaction.paypal_details.payer_email).not_to be_nil
        expect(transaction.paypal_details.authorization_id).not_to be_nil
        expect(transaction.paypal_details.payer_id).not_to be_nil
        expect(transaction.paypal_details.payer_first_name).not_to be_nil
        expect(transaction.paypal_details.payer_last_name).not_to be_nil
        expect(transaction.paypal_details.payer_status).not_to be_nil
        expect(transaction.paypal_details.seller_protection_status).not_to be_nil
        expect(transaction.paypal_details.capture_id).not_to be_nil
        expect(transaction.paypal_details.refund_id).not_to be_nil
        expect(transaction.paypal_details.transaction_fee_amount).not_to be_nil
        expect(transaction.paypal_details.transaction_fee_currency_iso_code).not_to be_nil
        expect(transaction.paypal_details.refund_from_transaction_fee_amount).not_to be_nil
        expect(transaction.paypal_details.refund_from_transaction_fee_currency_iso_code).not_to be_nil
      end
    end
  end

  describe "self.hold_in_escrow" do
    it "returns the transaction if successful" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::NonDefaultSubMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "12/12",
        },
        :service_fee_amount => "10.00",
      )

      expect(result.transaction.escrow_status).to be_nil
      result = Braintree::Transaction.hold_in_escrow(result.transaction.id)

      expect(result.success?).to be(true)
      expect(result.transaction.escrow_status).to eq(Braintree::Transaction::EscrowStatus::HoldPending)
    end

    it "returns an error result if the transaction cannot be held in escrow" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )

      result = Braintree::Transaction.hold_in_escrow(transaction.id)
      expect(result.errors.for(:transaction).on(:base)[0].code).to eq(Braintree::ErrorCodes::Transaction::CannotHoldInEscrow)
    end
  end

  describe "self.hold_in_escrow!" do
    it "returns the transaction if successful" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::NonDefaultSubMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "12/12",
        },
        :service_fee_amount => "10.00",
      )

      expect(result.transaction.escrow_status).to be_nil
      transaction = Braintree::Transaction.hold_in_escrow!(result.transaction.id)

      expect(transaction.escrow_status).to eq(Braintree::Transaction::EscrowStatus::HoldPending)
    end

    it "raises an error if the transaction cannot be held in escrow" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )

      expect do
        Braintree::Transaction.hold_in_escrow!(transaction.id)
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.void" do
    it "returns a successful result if successful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )
      result = Braintree::Transaction.void(transaction.id)
      expect(result.success?).to eq(true)
      expect(result.transaction.id).to eq(transaction.id)
      expect(result.transaction.status).to eq(Braintree::Transaction::Status::Voided)
    end

    it "returns an error result if unsuccessful" do
      transaction = Braintree::Transaction.sale(
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      ).transaction
      result = Braintree::Transaction.void(transaction.id)
      expect(result.success?).to eq(false)
      expect(result.errors.for(:transaction).on(:base)[0].code).to eq(Braintree::ErrorCodes::Transaction::CannotBeVoided)
    end
  end

  describe "self.void!" do
    it "returns the transaction if successful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )
      returned_transaction = Braintree::Transaction.void!(transaction.id)
      expect(returned_transaction).to eq(transaction)
      expect(returned_transaction.status).to eq(Braintree::Transaction::Status::Voided)
    end

    it "raises a ValidationsFailed if unsuccessful" do
      transaction = Braintree::Transaction.sale(
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      ).transaction
      expect do
        Braintree::Transaction.void!(transaction.id)
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "status_history" do
    it "returns an array of StatusDetail" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
      )
      result = Braintree::Transaction.submit_for_settlement!(transaction.id)
      expect(result.status_history.size).to eq(2)
      expect(result.status_history[0].status).to eq(Braintree::Transaction::Status::Authorized)
      expect(result.status_history[1].status).to eq(Braintree::Transaction::Status::SubmittedForSettlement)
    end
  end

  describe "authorization_adjustments" do
    it "includes authorization adjustments on found transactions" do
      found_transaction = Braintree::Transaction.find("authadjustmenttransaction")

      expect(found_transaction.authorization_adjustments.count).to eq(1)

      authorization_adjustment = found_transaction.authorization_adjustments.first
      expect(authorization_adjustment.amount).to eq("-20.00")
      expect(authorization_adjustment.success).to eq(true)
      expect(authorization_adjustment.timestamp).to be_a Time
      expect(authorization_adjustment.processor_response_code).to eq("1000")
      expect(authorization_adjustment.processor_response_text).to eq("Approved")
    end

    it "includes authorization adjustments soft declined on found transactions" do
      found_transaction = Braintree::Transaction.find("authadjustmenttransactionsoftdeclined")

      expect(found_transaction.authorization_adjustments.count).to eq(1)

      authorization_adjustment = found_transaction.authorization_adjustments.first
      expect(authorization_adjustment.amount).to eq("-20.00")
      expect(authorization_adjustment.success).to eq(false)
      expect(authorization_adjustment.timestamp).to be_a Time
      expect(authorization_adjustment.processor_response_code).to eq("3000")
      expect(authorization_adjustment.processor_response_text).to eq("Processor Network Unavailable - Try Again")
      expect(authorization_adjustment.processor_response_type).to eq(Braintree::ProcessorResponseTypes::SoftDeclined)
    end

    it "includes authorization adjustments hard declined on found transactions" do
      found_transaction = Braintree::Transaction.find("authadjustmenttransactionharddeclined")

      expect(found_transaction.authorization_adjustments.count).to eq(1)

      authorization_adjustment = found_transaction.authorization_adjustments.first
      expect(authorization_adjustment.amount).to eq("-20.00")
      expect(authorization_adjustment.success).to eq(false)
      expect(authorization_adjustment.timestamp).to be_a Time
      expect(authorization_adjustment.processor_response_code).to eq("2015")
      expect(authorization_adjustment.processor_response_text).to eq("Transaction Not Allowed")
      expect(authorization_adjustment.processor_response_type).to eq(Braintree::ProcessorResponseTypes::HardDeclined)
    end
  end

  describe "vault_credit_card" do
    it "returns the Braintree::CreditCard if the transaction credit card is stored in the vault" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        },
      )
      transaction = Braintree::CreditCard.sale(customer.credit_cards[0].token, {:amount => "100.00"}).transaction
      expect(transaction.vault_credit_card).to eq(customer.credit_cards[0])
    end

    it "returns nil if the transaction credit card is not stored in the vault" do
      transaction = Braintree::Transaction.create!(
        :amount => "100.00",
        :type => "sale",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        },
      )
      expect(transaction.vault_credit_card).to eq(nil)
    end
  end

  describe "vault_customer" do
    it "returns the Braintree::Customer if the transaction customer is stored in the vault" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        },
      )
      transaction = Braintree::CreditCard.sale(customer.credit_cards[0].token, :amount => "100.00").transaction
      expect(transaction.vault_customer).to eq(customer)
    end

    it "returns nil if the transaction customer is not stored in the vault" do
      transaction = Braintree::Transaction.create!(
        :amount => "100.00",
        :type => "sale",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        },
      )
      expect(transaction.vault_customer).to eq(nil)
    end
  end

  def create_transaction_to_refund
    transaction = Braintree::Transaction.sale!(
      :amount => Braintree::Test::TransactionAmounts::Authorize,
      :credit_card => {
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2009"
      },
      :options => {
        :submit_for_settlement => true
      },
    )

    config = Braintree::Configuration.instantiate
    config.http.put("#{config.base_merchant_path}/transactions/#{transaction.id}/settle")
    Braintree::Transaction.find(transaction.id)
  end

  def create_paypal_transaction_for_refund
    transaction = Braintree::Transaction.sale!(
      :amount => Braintree::Test::TransactionAmounts::Authorize,
      :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
      :options => {
        :submit_for_settlement => true
      },
    )

    config = Braintree::Configuration.instantiate
    config.http.put("#{config.base_merchant_path}/transactions/#{transaction.id}/settle")
    Braintree::Transaction.find(transaction.id)
  end

  def create_escrowed_transcation
    transaction = Braintree::Transaction.sale!(
      :amount => Braintree::Test::TransactionAmounts::Authorize,
      :merchant_account_id => SpecHelper::NonDefaultSubMerchantAccountId,
      :credit_card => {
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2009"
      },
      :service_fee_amount => "1.00",
      :options => {:hold_in_escrow => true},
    )

    config = Braintree::Configuration.instantiate
    config.http.put("#{config.base_merchant_path}/transactions/#{transaction.id}/settle")
    config.http.put("#{config.base_merchant_path}/transactions/#{transaction.id}/escrow")
    Braintree::Transaction.find(transaction.id)
  end

  context "paypal" do
    it "can create a transaction for a paypal account" do
      result = Braintree::Transaction.sale(
        :amount => "10.00",
        :payment_method_nonce => Braintree::Test::Nonce::PayPalFuturePayment,
      )
      expect(result.success?).to eq(true)
      expect(result.transaction.paypal_details.payer_email).to eq("payer@example.com")
      expect(result.transaction.paypal_details.payment_id).to match(/PAY-\w+/)
      expect(result.transaction.paypal_details.authorization_id).to match(/AUTH-\w+/)
      expect(result.transaction.paypal_details.image_url).not_to be_nil
    end

    it "can vault a paypal account on a transaction" do
      result = Braintree::Transaction.sale(
        :amount => "10.00",
        :payment_method_nonce => Braintree::Test::Nonce::PayPalFuturePayment,
        :options => {
          :store_in_vault => true
        },
      )
      expect(result.success?).to eq(true)
      expect(result.transaction.paypal_details.token).not_to be_nil
      expect(result.transaction.paypal_details.payer_email).to eq("payer@example.com")
      expect(result.transaction.paypal_details.payment_id).to match(/PAY-\w+/)
      expect(result.transaction.paypal_details.authorization_id).to match(/AUTH-\w+/)
    end

    it "can create a transaction from a vaulted paypal account" do
      customer = Braintree::Customer.create!
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => Braintree::Test::Nonce::PayPalFuturePayment,
        :customer_id => customer.id,
      )

      expect(result).to be_success
      expect(result.payment_method).to be_a(Braintree::PayPalAccount)
      payment_method_token = result.payment_method.token

      result = Braintree::Transaction.sale(
        :amount => "100",
        :customer_id => customer.id,
        :payment_method_token => payment_method_token,
      )

      expect(result).to be_success
      expect(result.transaction.paypal_details.token).to eq(payment_method_token)
      expect(result.transaction.paypal_details.payer_email).to eq("payer@example.com")
      expect(result.transaction.paypal_details.payment_id).to match(/PAY-\w+/)
      expect(result.transaction.paypal_details.authorization_id).to match(/AUTH-\w+/)
    end

    context "validation failure" do
      it "returns a validation error if consent code and access token are omitted" do
        nonce = nonce_for_paypal_account(:token => "TOKEN")
        result = Braintree::Transaction.sale(
          :amount => "10.00",
          :payment_method_nonce => nonce,
        )
        expect(result).not_to be_success
        expect(result.errors.for(:transaction).for(:paypal_account).first.code).to eq(Braintree::ErrorCodes::PayPalAccount::IncompletePayPalAccount)
      end
    end
  end

  context "shared payment method" do
    before(:each) do
      @partner_merchant_gateway = Braintree::Gateway.new(
        :merchant_id => "integration_merchant_public_id",
        :public_key => "oauth_app_partner_user_public_key",
        :private_key => "oauth_app_partner_user_private_key",
        :environment => Braintree::Configuration.environment,
        :logger => Logger.new("/dev/null"),
      )
      @customer = @partner_merchant_gateway.customer.create(
        :first_name => "Joe",
        :last_name => "Brown",
        :company => "ExampleCo",
        :email => "joe@example.com",
        :phone => "312.555.1234",
        :fax => "614.555.5678",
        :website => "www.example.com",
      ).customer
      @address = @partner_merchant_gateway.address.create(
        :customer_id => @customer.id,
        :first_name => "Testy",
        :last_name => "McTesterson",
      ).address
      @credit_card = @partner_merchant_gateway.credit_card.create(
        :customer_id => @customer.id,
        :cardholder_name => "Adam Davis",
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2009",
        :billing_address => {
          :first_name => "Adam",
          :last_name => "Davis",
          :postal_code => "95131"
        },
      ).credit_card

      oauth_gateway = Braintree::Gateway.new(
        :client_id => "client_id$#{Braintree::Configuration.environment}$integration_client_id",
        :client_secret => "client_secret$#{Braintree::Configuration.environment}$integration_client_secret",
        :logger => Logger.new("/dev/null"),
      )
      access_token = Braintree::OAuthTestHelper.create_token(oauth_gateway, {
        :merchant_public_id => "integration_merchant_id",
        :scope => "grant_payment_method,shared_vault_transactions"
      }).credentials.access_token

      @granting_gateway = Braintree::Gateway.new(
        :access_token => access_token,
        :logger => Logger.new("/dev/null"),
      )

    end

    it "oauth app details are returned on transaction created via nonce granting" do
      grant_result = @granting_gateway.payment_method.grant(@credit_card.token, false)

      result = Braintree::Transaction.sale(
        :payment_method_nonce => grant_result.payment_method_nonce.nonce,
        :amount => Braintree::Test::TransactionAmounts::Authorize,
      )
      expect(result.transaction.facilitated_details.merchant_id).to eq("integration_merchant_id")
      expect(result.transaction.facilitated_details.merchant_name).to eq("14ladders")
      expect(result.transaction.facilitated_details.payment_method_nonce).to eq(grant_result.payment_method_nonce.nonce)
      expect(result.transaction.facilitator_details).not_to eq(nil)
      expect(result.transaction.facilitator_details.oauth_application_client_id).to eq("client_id$#{Braintree::Configuration.environment}$integration_client_id")
      expect(result.transaction.facilitator_details.oauth_application_name).to eq("PseudoShop")
      result.transaction.billing_details.postal_code == nil
    end

    it "billing postal code is returned on transaction created via nonce granting when specified in the grant request" do
      grant_result = @granting_gateway.payment_method.grant(@credit_card.token, :allow_vaulting => false, :include_billing_postal_code => true)

      result = Braintree::Transaction.sale(
        :payment_method_nonce => grant_result.payment_method_nonce.nonce,
        :amount => Braintree::Test::TransactionAmounts::Authorize,
      )

      result.transaction.billing_details.postal_code == "95131"
    end

    it "allows transactions to be created with a shared payment method, customer, billing and shipping addresses" do
      result = @granting_gateway.transaction.sale(
        :shared_payment_method_token => @credit_card.token,
        :shared_customer_id => @customer.id,
        :shared_shipping_address_id => @address.id,
        :shared_billing_address_id => @address.id,
        :amount => Braintree::Test::TransactionAmounts::Authorize,
      )
      expect(result.success?).to eq(true)
      expect(result.transaction.shipping_details.first_name).to eq(@address.first_name)
      expect(result.transaction.billing_details.first_name).to eq(@address.first_name)
    end

    it "facilitated details are returned on transaction created via a shared_payment_method_token" do
      result = @granting_gateway.transaction.sale(
        :shared_payment_method_token => @credit_card.token,
        :amount => Braintree::Test::TransactionAmounts::Authorize,
      )
      expect(result.transaction.facilitated_details.merchant_id).to eq("integration_merchant_id")
      expect(result.transaction.facilitated_details.merchant_name).to eq("14ladders")
      expect(result.transaction.facilitated_details.payment_method_nonce).to eq(nil)
      expect(result.transaction.facilitator_details).not_to eq(nil)
      expect(result.transaction.facilitator_details.oauth_application_client_id).to eq("client_id$#{Braintree::Configuration.environment}$integration_client_id")
      expect(result.transaction.facilitator_details.oauth_application_name).to eq("PseudoShop")
    end

    it "facilitated details are returned on transaction created via a shared_payment_method_nonce" do
      shared_nonce = @partner_merchant_gateway.payment_method_nonce.create(
        @credit_card.token,
      ).payment_method_nonce.nonce

      result = @granting_gateway.transaction.sale(
        :shared_payment_method_nonce => shared_nonce,
        :amount => Braintree::Test::TransactionAmounts::Authorize,
      )
      expect(result.transaction.facilitated_details.merchant_id).to eq("integration_merchant_id")
      expect(result.transaction.facilitated_details.merchant_name).to eq("14ladders")
      expect(result.transaction.facilitated_details.payment_method_nonce).to eq(nil)
      expect(result.transaction.facilitator_details).not_to eq(nil)
      expect(result.transaction.facilitator_details.oauth_application_client_id).to eq("client_id$#{Braintree::Configuration.environment}$integration_client_id")
      expect(result.transaction.facilitator_details.oauth_application_name).to eq("PseudoShop")
    end
  end

  context "paypal here" do
    it "gets the details of an auth/capture transaction" do
      result = Braintree::Transaction.find("paypal_here_auth_capture_id")
      expect(result.payment_instrument_type).to eq(Braintree::PaymentInstrumentType::PayPalHere)
      expect(result.paypal_here_details).not_to be_nil

      details = result.paypal_here_details
      expect(details.authorization_id).not_to be_nil
      expect(details.capture_id).not_to be_nil
      expect(details.invoice_id).not_to be_nil
      expect(details.last_4).not_to be_nil
      expect(details.payment_type).not_to be_nil
      expect(details.transaction_fee_amount).not_to be_nil
      expect(details.transaction_fee_currency_iso_code).not_to be_nil
      expect(details.transaction_initiation_date).not_to be_nil
      expect(details.transaction_updated_date).not_to be_nil
    end

    it "gets the details of a sale transaction" do
      result = Braintree::Transaction.find("paypal_here_sale_id")
      expect(result.paypal_here_details).not_to be_nil

      details = result.paypal_here_details
      expect(details.payment_id).not_to be_nil
    end

    it "gets the details of a refunded sale transaction" do
      result = Braintree::Transaction.find("paypal_here_refund_id")
      expect(result.paypal_here_details).not_to be_nil

      details = result.paypal_here_details
      expect(details.refund_id).not_to be_nil
    end
  end

  describe "card on file network tokenization" do
    it "creates a transaction with a vaulted, tokenized credit card" do
      result = Braintree::Transaction.sale(
        :amount => "112.44",
        :payment_method_token => "network_tokenized_credit_card",
      )
      expect(result.success?).to eq(true)
      transaction = result.transaction

      expect(transaction.amount).to eq(BigDecimal("112.44"))
      expect(transaction.processed_with_network_token?).to eq(true)
    end

    it "creates a transaction with a vaulted, non-tokenized credit card" do
      customer = Braintree::Customer.create!
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => Braintree::Test::Nonce::TransactableVisa,
        :customer_id => customer.id,
      )
      payment_method_token = result.payment_method.token

      result = Braintree::Transaction.sale(
        :amount => "112.44",
        :payment_method_token => payment_method_token,
      )
      expect(result.success?).to eq(true)
      transaction = result.transaction

      expect(transaction.amount).to eq(BigDecimal("112.44"))
      expect(transaction.processed_with_network_token?).to eq(false)
    end
  end

  describe "retried flag presence in response" do
    it "creates a retried transaction" do
      result = Braintree::Transaction.sale(
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :payment_method_token => "network_tokenized_credit_card",
      )

      transaction = result.transaction
      expect(transaction.retried).to eq(true)
    end

    it "creates a non-retried transaction" do
      result = Braintree::Transaction.sale(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :payment_method_token => "network_tokenized_credit_card",
      )
      transaction = result.transaction

      expect(transaction.retried).to be_falsey
    end

    it "creates a transaction that is ineligible for retries" do
      result = Braintree::Transaction.sale(
        :merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
        :amount => Braintree::Test::TransactionAmounts::Authorize,
      )
      transaction = result.transaction

      expect(transaction.retried).to be_falsey
    end
  end

  describe "retried_transaction_id and retry_ids presence in transaction response" do
    context "when it creates a retried transaction" do
      it "has retry_ids in the first transaction" do
        result = Braintree::Transaction.sale(
          :amount => Braintree::Test::TransactionAmounts::Decline,
          :payment_method_token => "network_tokenized_credit_card",
          :merchant_account_id => "ma_transaction_multiple_retries",
        )

        transaction = result.transaction
        expect(transaction.retried_transaction_id).to eq(nil)
        expect(transaction.retry_ids).not_to eq([])
        expect(transaction.retry_ids.count).to eq(2)

        # verify retried_transaction_id is in the all retried transactions
        retry_transaction_1 = transaction.retry_ids[0]
        collection_1 = Braintree::Transaction.search do |search|
          search.id.is retry_transaction_1
        end
        expect(collection_1.maximum_size).to eq(1)
        expect(collection_1.first.retried_transaction_id).not_to eq(nil)
        expect(collection_1.first.retried_transaction_id).to eq(transaction.id)

        retry_transaction_2 = transaction.retry_ids[1]
        collection_2 = Braintree::Transaction.search do |search|
          search.id.is retry_transaction_2
        end
        expect(collection_2.maximum_size).to eq(1)
        expect(collection_2.first.retried_transaction_id).not_to eq(nil)
        expect(collection_2.first.retried_transaction_id).to eq(transaction.id)
      end
    end

    context "when it creates a non-retried transaction" do
      it "does not have retried_transaction_id and retry_ids in the transaction" do
        result = Braintree::Transaction.sale(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_token => "network_tokenized_credit_card",
        )

        transaction = result.transaction
        expect(transaction.retried_transaction_id).to eq(nil)
        expect(transaction.retry_ids).to eq([])
      end
    end
  end

  describe "installments" do
    it "creates a transaction with an installment count" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :merchant_account_id => SpecHelper::CardProcessorBRLMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
        :amount => "100.01",
        :installments => {
          :count => 12,
        },
      )

      expect(result.success?).to eq(true)
      expect(result.transaction.installment_count).to eq(12)
    end

    it "creates a transaction with a installments during capture" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :merchant_account_id => SpecHelper::CardProcessorBRLMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
        :amount => "100.01",
        :installments => {
          :count => 12,
        },
        :options => {
          :submit_for_settlement => true,
        },
      )

      expect(result.success?).to eq(true)
      transaction = result.transaction
      expect(transaction.installment_count).to eq(12)

      installments = transaction.installments
      expect(installments.map(&:id)).to match_array((1..12).map { |i| "#{transaction.id}_INST_#{i}" })
      expect(installments.map(&:amount)).to match_array([BigDecimal("8.33")] * 11 + [BigDecimal("8.38")])
    end

    it "can refund a transaction with installments" do
      sale_result = Braintree::Transaction.create(
        :type => "sale",
        :merchant_account_id => SpecHelper::CardProcessorBRLMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
        :amount => "100.01",
        :installments => {
          :count => 12,
        },
        :options => {
          :submit_for_settlement => true,
        },
      )

      expect(sale_result.success?).to eq(true)
      sale_transaction = sale_result.transaction

      refund_result = Braintree::Transaction.refund(sale_transaction.id, "49.99")

      expect(refund_result.success?).to eq(true)
      refund_transaction = refund_result.transaction
      installments = refund_transaction.refunded_installments

      (1..11).each do |i|
        installment = installments.find { |installment| installment.id == "#{sale_transaction.id}_INST_#{i}" }

        expect(installment.amount).to eq(BigDecimal("8.33"))
        expect(installment.adjustments.map(&:amount)).to match_array([BigDecimal("-4.16")])
        expect(installment.adjustments.map(&:kind)).to match_array([Braintree::Transaction::Installment::Adjustment::Kind::Refund])
      end

      installment = installments.find { |installment| installment.id == "#{sale_transaction.id}_INST_12" }

      expect(installment.amount).to eq(BigDecimal("8.38"))
      expect(installment.adjustments.map(&:amount)).to match_array([BigDecimal("-4.23")])
      expect(installment.adjustments.map(&:kind)).to match_array([Braintree::Transaction::Installment::Adjustment::Kind::Refund])
    end
  end

  describe "Manual Key Entry" do
    context "with correct encrypted payment reader card details" do
      it "returns a success response" do
        result = Braintree::Transaction.sale(
          :amount => "10.00",
          :credit_card => {
            :payment_reader_card_details => {
              :encrypted_card_data => "8F34DFB312DC79C24FD5320622F3E11682D79E6B0C0FD881",
              :key_serial_number => "FFFFFF02000572A00005",
            },
          },
        )

        expect(result).to be_success
      end
    end

    context "with invalid encrypted payment reader card details" do
      it "returns a failure response" do
        result = Braintree::Transaction.sale(
          :amount => "10.00",
          :credit_card => {
            :payment_reader_card_details => {
              :encrypted_card_data => "invalid",
              :key_serial_number => "invalid",
            },
          },
        )

        expect(result).not_to be_success
        expect(result.errors.for(:transaction).first.code)
          .to eq(Braintree::ErrorCodes::Transaction::PaymentInstrumentNotSupportedByMerchantAccount)
      end
    end
  end

  describe "Adjust Authorization" do
    let(:first_data_master_transaction_params) do
      {
        :merchant_account_id => SpecHelper::FakeFirstDataMerchantAccountId,
        :amount => "75.50",
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        }
      }
    end
    let(:first_data_visa_transaction_params) do
      {
        :merchant_account_id => SpecHelper::FakeFirstDataMerchantAccountId,
        :amount => "75.50",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      }
    end
    context "successful authorization" do
      it "returns success response" do
        initial_transaction = Braintree::Transaction.sale(first_data_master_transaction_params)
        expect(initial_transaction.success?).to eq(true)

        adjustment_transaction = Braintree::Transaction.adjust_authorization(
          initial_transaction.transaction.id, "85.50"
        )

        expect(adjustment_transaction.success?).to eq(true)
        expect(adjustment_transaction.transaction.amount).to eq(BigDecimal("85.50"))
      end
    end

    context "unsuccessful authorization" do
      it "returns failure, when processor does not support multi auth adjustment" do
        initial_transaction = Braintree::Transaction.sale(
          :merchant_account_id => SpecHelper::DefaultMerchantAccountId,
          :amount => "75.50",
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "06/2009"
          },
        )
        expect(initial_transaction.success?).to eq(true)

        adjustment_transaction = Braintree::Transaction.adjust_authorization(
          initial_transaction.transaction.id, "85.50"
        )


        expect(adjustment_transaction.success?).to eq(false)
        expect(adjustment_transaction.transaction.amount).to eq(BigDecimal("75.50"))
        expect(adjustment_transaction.errors.for(:transaction).on(:base).first.code).to eq(Braintree::ErrorCodes::Transaction::ProcessorDoesNotSupportAuthAdjustment)
      end

      it "returns failure response, when adjusted amount submitted is zero" do
        initial_transaction = Braintree::Transaction.sale(first_data_master_transaction_params)
        expect(initial_transaction.success?).to eq(true)

        adjustment_transaction = Braintree::Transaction.adjust_authorization(
          initial_transaction.transaction.id, "0.0"
        )

        expect(adjustment_transaction.success?).to eq(false)
        expect(adjustment_transaction.transaction.amount).to eq(BigDecimal("75.50"))
        expect(adjustment_transaction.errors.for(:authorization_adjustment).on(:amount).first.code).to eq(Braintree::ErrorCodes::Transaction::AdjustmentAmountMustBeGreaterThanZero)
      end

      it "returns failure response, when adjusted amount submitted same as authorized amount" do
        initial_transaction = Braintree::Transaction.sale(first_data_master_transaction_params)
        expect(initial_transaction.success?).to eq(true)

        adjustment_transaction = Braintree::Transaction.adjust_authorization(
          initial_transaction.transaction.id, "75.50"
        )

        expect(adjustment_transaction.success?).to eq(false)
        expect(adjustment_transaction.transaction.amount).to eq(BigDecimal("75.50"))
        expect(adjustment_transaction.errors.for(:authorization_adjustment).on(:base).first.code).to eq(Braintree::ErrorCodes::Transaction::NoNetAmountToPerformAuthAdjustment)
      end

      it "returns failure, when transaction authorization type final or undefined" do
        additional_params = {:transaction_source => "recurring"}
        initial_transaction = Braintree::Transaction.sale(first_data_master_transaction_params.merge(additional_params))
        expect(initial_transaction.success?).to eq(true)

        adjustment_transaction = Braintree::Transaction.adjust_authorization(
          initial_transaction.transaction.id, "85.50"
        )

        expect(adjustment_transaction.success?).to eq(false)
        expect(adjustment_transaction.transaction.amount).to eq(BigDecimal("75.50"))
        expect(adjustment_transaction.errors.for(:transaction).on(:base).first.code).to eq(Braintree::ErrorCodes::Transaction::TransactionIsNotEligibleForAdjustment)
      end
    end
  end

  context "Merchant Advice Code" do
    it "exposes MAC and MAC text" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => DateTime.now.strftime("%m/%Y")
        },
      )
      expect(result.transaction.merchant_advice_code).to eq("01")
      expect(result.transaction.merchant_advice_code_text).to eq("New account information available")
    end
  end
end
