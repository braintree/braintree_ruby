require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::Transaction do
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
        }
      )
      result.success?.should == true

      clone_result = Braintree::Transaction.clone_transaction(
        result.transaction.id,
        :amount => "112.44",
        :channel => "MyShoppingCartProvider",
        :options => {
          :submit_for_settlement => false
        }
      )
      clone_result.success?.should == true

      transaction = clone_result.transaction

      transaction.id.should_not == result.transaction.id
      transaction.amount.should == BigDecimal.new("112.44")
      transaction.channel.should == "MyShoppingCartProvider"

      transaction.billing_details.country_name.should == "Botswana"
      transaction.billing_details.country_code_alpha2.should == "BW"
      transaction.billing_details.country_code_alpha3.should == "BWA"
      transaction.billing_details.country_code_numeric.should == "072"

      transaction.shipping_details.country_name.should == "Bhutan"
      transaction.shipping_details.country_code_alpha2.should == "BT"
      transaction.shipping_details.country_code_alpha3.should == "BTN"
      transaction.shipping_details.country_code_numeric.should == "064"

      transaction.credit_card_details.masked_number.should == "510510******5100"
      transaction.credit_card_details.expiration_date.should == "05/2012"

      transaction.customer_details.last_name.should == "Adama"
      transaction.status.should == Braintree::Transaction::Status::Authorized
    end

    it "submit for settlement option" do
      result = Braintree::Transaction.sale(
        :amount => "112.44",
        :credit_card => {
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        }
      )

      result.success?.should be_true

      clone_result = Braintree::Transaction.clone_transaction(result.transaction.id, :amount => "112.44", :options => {:submit_for_settlement => true})
      clone_result.success?.should == true

      clone_result.transaction.status.should == Braintree::Transaction::Status::SubmittedForSettlement
    end

    it "handles validation errors" do
      transaction = Braintree::Transaction.credit!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      result = Braintree::Transaction.clone_transaction(transaction.id, :amount => "112.44")
      result.success?.should be_false

      result.errors.for(:transaction).on(:base).first.code.should == Braintree::ErrorCodes::Transaction::CannotCloneCredit
    end
  end

  describe "self.clone_transaction!" do
    it "returns the transaction if valid" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      clone_transaction = Braintree::Transaction.clone_transaction!(transaction.id, :amount => "112.44", :options => {:submit_for_settlement => false})
      clone_transaction.id.should_not == transaction.id
    end

    it "raises a validationsfailed if invalid" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      expect do
        clone_transaction = Braintree::Transaction.clone_transaction!(transaction.id, :amount => "im not a number")
        clone_transaction.id.should_not == transaction.id
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.create" do
    describe "card type indicators" do
      it "sets the prepaid field if the card is prepaid" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => 1_00,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::CardTypeIndicators::Prepaid,
            :expiration_date => "05/2009"
          }
        )
        result.transaction.credit_card_details.prepaid.should == Braintree::CreditCard::Prepaid::Yes
      end
    end

    it "returns a successful result if successful" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      result.success?.should == true
      result.transaction.id.should =~ /^\w{6}$/
      result.transaction.type.should == "sale"
      result.transaction.amount.should == BigDecimal.new(Braintree::Test::TransactionAmounts::Authorize)
      result.transaction.processor_authorization_code.should_not be_nil
      result.transaction.voice_referral_number.should be_nil
      result.transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      result.transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      result.transaction.credit_card_details.expiration_date.should == "05/2009"
      result.transaction.credit_card_details.customer_location.should == "US"
    end

    it "accepts additional security parameters: device_session_id and fraud_merchant_id" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
        :device_session_id => "abc123",
        :fraud_merchant_id => "7"
      )

      result.success?.should == true
    end

    it "accepts billing_address_id in place of billing_address" do
      result = Braintree::Customer.create()
      address_result = Braintree::Address.create(
        :customer_id => result.customer.id,
        :country_code_alpha2 => "US"
      )

      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :customer_id => result.customer.id,
        :billing_address_id => address_result.address.id,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )

      result.success?.should == true
    end

    it "returns processor response code and text if declined" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      result.success?.should == false
      result.transaction.id.should =~ /^\w{6}$/
      result.transaction.type.should == "sale"
      result.transaction.status.should == Braintree::Transaction::Status::ProcessorDeclined
      result.transaction.processor_response_code.should == "2000"
      result.transaction.processor_response_text.should == "Do Not Honor"
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
        }
      )
      result.success?.should == true
      transaction = result.transaction
      transaction.billing_details.country_name.should == "Botswana"
      transaction.billing_details.country_code_alpha2.should == "BW"
      transaction.billing_details.country_code_alpha3.should == "BWA"
      transaction.billing_details.country_code_numeric.should == "072"

      transaction.shipping_details.country_name.should == "Bhutan"
      transaction.shipping_details.country_code_alpha2.should == "BT"
      transaction.shipping_details.country_code_alpha3.should == "BTN"
      transaction.shipping_details.country_code_numeric.should == "064"

      transaction.vault_credit_card.billing_address.country_name.should == "Botswana"
      transaction.vault_credit_card.billing_address.country_code_alpha2.should == "BW"
      transaction.vault_credit_card.billing_address.country_code_alpha3.should == "BWA"
      transaction.vault_credit_card.billing_address.country_code_numeric.should == "072"
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
        }
      )

      result.success?.should == false
      result.errors.for(:transaction).for(:billing).on(:base).map { |e| e.code }.should include(Braintree::ErrorCodes::Address::InconsistentCountry)
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
        }
      )

      result.success?.should == false
      codes = result.errors.for(:transaction).for(:billing).on(:country_code_alpha2).map { |e| e.code }
      codes.should include(Braintree::ErrorCodes::Address::CountryCodeAlpha2IsNotAccepted)
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
        }
      )

      result.success?.should == false
      codes = result.errors.for(:transaction).for(:billing).on(:country_code_alpha3).map { |e| e.code }
      codes.should include(Braintree::ErrorCodes::Address::CountryCodeAlpha3IsNotAccepted)
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
        }
      )

      result.success?.should == false
      codes = result.errors.for(:transaction).for(:billing).on(:country_code_numeric).map { |e| e.code }
      codes.should include(Braintree::ErrorCodes::Address::CountryCodeNumericIsNotAccepted)
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
            }
          )
          result.success?.should == false
          result.transaction.gateway_rejection_reason.should == Braintree::Transaction::GatewayRejectionReason::CVV
        ensure
          Braintree::Configuration.merchant_id = old_merchant
          Braintree::Configuration.public_key = old_public_key
          Braintree::Configuration.private_key = old_private_key
        end
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
            }
          )
          result.success?.should == false
          result.transaction.gateway_rejection_reason.should == Braintree::Transaction::GatewayRejectionReason::AVS
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
            }
          )
          result.success?.should == false
          result.transaction.gateway_rejection_reason.should == Braintree::Transaction::GatewayRejectionReason::AVSAndCVV
        ensure
          Braintree::Configuration.merchant_id = old_merchant
          Braintree::Configuration.public_key = old_public_key
          Braintree::Configuration.private_key = old_private_key
        end
      end

      it "exposes the fraud gateway rejection reason" do
        result = Braintree::Transaction.sale(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Fraud,
            :expiration_date => "05/2017",
            :cvv => "333"
          }
        )
        result.success?.should == false
        result.transaction.gateway_rejection_reason.should == Braintree::Transaction::GatewayRejectionReason::Fraud
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
        }
      )
      result.success?.should == true
      result.transaction.credit_card_details.expiration_month.should == "05"
      result.transaction.credit_card_details.expiration_year.should == "2011"
      result.transaction.credit_card_details.expiration_date.should == "05/2011"
    end

    it "returns some error if customer_id is invalid" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :customer_id => 123456789
      )
      result.success?.should == false
      result.errors.for(:transaction).on(:customer_id)[0].code.should == "91510"
      result.message.should == "Customer ID is invalid."
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
        }
      )
      result.success?.should == true
      result.transaction.custom_fields.should == {:store_me => "custom value"}
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
        }
      )

      result = Braintree::Transaction.find(create_result.transaction.id)

      result.custom_fields.should == {}
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
        }
      )
      result.success?.should == false
      result.errors.for(:transaction).on(:custom_fields)[0].message.should == "Custom field is invalid: invalid_key."
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
      result.success?.should == false
      result.params.should == {:transaction => {:type => 'sale', :amount => nil, :credit_card => {:expiration_date => "05/2009"}}}
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
      result.success?.should == false
      result.errors.for(:transaction).on(:base).map{|error| error.code}.should include(Braintree::ErrorCodes::Transaction::PaymentMethodConflictWithVenmoSDK)
      result.errors.for(:transaction).on(:base).map{|error| error.code}.should include(Braintree::ErrorCodes::Transaction::PaymentMethodDoesNotBelongToCustomer)
      result.errors.for(:transaction).on(:amount)[0].code.should == Braintree::ErrorCodes::Transaction::AmountIsRequired
      result.errors.for(:transaction).on(:customer_id)[0].code.should == Braintree::ErrorCodes::Transaction::CustomerIdIsInvalid
      result.errors.for(:transaction).on(:order_id)[0].code.should == Braintree::ErrorCodes::Transaction::OrderIdIsTooLong
      result.errors.for(:transaction).on(:channel)[0].code.should == Braintree::ErrorCodes::Transaction::ChannelIsTooLong
      result.errors.for(:transaction).on(:payment_method_token)[0].code.should == Braintree::ErrorCodes::Transaction::PaymentMethodTokenIsInvalid
      result.errors.for(:transaction).on(:type)[0].code.should == Braintree::ErrorCodes::Transaction::TypeIsInvalid
    end

    it "returns an error if amount is negative" do
      params = {
        :transaction => {
          :type => "credit",
          :amount => "-1"
        }
      }
      result = Braintree::Transaction.create(params[:transaction])
      result.success?.should == false
      result.errors.for(:transaction).on(:amount)[0].code.should == Braintree::ErrorCodes::Transaction::AmountCannotBeNegative
    end

    it "returns an error if amount is invalid format" do
      params = {
        :transaction => {
          :type => "sale",
          :amount => "shorts"
        }
      }
      result = Braintree::Transaction.create(params[:transaction])
      result.success?.should == false
      result.errors.for(:transaction).on(:amount)[0].code.should == Braintree::ErrorCodes::Transaction::AmountIsInvalid
    end

    it "returns an error if type is not given" do
      params = {
        :transaction => {
          :type => nil
        }
      }
      result = Braintree::Transaction.create(params[:transaction])
      result.success?.should == false
      result.errors.for(:transaction).on(:type)[0].code.should == Braintree::ErrorCodes::Transaction::TypeIsRequired
    end

    it "returns an error if no credit card is given" do
      params = {
        :transaction => {
        }
      }
      result = Braintree::Transaction.create(params[:transaction])
      result.success?.should == false
      result.errors.for(:transaction).on(:base)[0].code.should == Braintree::ErrorCodes::Transaction::CreditCardIsRequired
    end

    it "returns an error if the given payment method token doesn't belong to the customer" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :customer_id => customer.id,
        :payment_method_token => customer.credit_cards[0].token + "x"
      )
      result.success?.should == false
      result.errors.for(:transaction).on(:base)[0].code.should == Braintree::ErrorCodes::Transaction::PaymentMethodDoesNotBelongToCustomer
    end

    context "new credit card for existing customer" do
      it "allows a new credit card to be used for an existing customer" do
        customer = Braintree::Customer.create!(
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2010"
          }
        )
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :customer_id => customer.id,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12"
          }
        )
        result.success?.should == true
        result.transaction.credit_card_details.masked_number.should == "401288******1881"
        result.transaction.vault_credit_card.should be_nil
      end

      it "allows a new credit card to be used and stored in the vault" do
        customer = Braintree::Customer.create!(
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2010"
          }
        )
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :customer_id => customer.id,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :options => { :store_in_vault => true }
        )
        result.success?.should == true
        result.transaction.credit_card_details.masked_number.should == "401288******1881"
        result.transaction.vault_credit_card.masked_number.should == "401288******1881"
      end
    end

    it "snapshots plan, add_ons and discounts from subscription" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )

      result = Braintree::Subscription.create(
        :payment_method_token => customer.credit_cards.first.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :add_ons => {
          :add => [
            {
              :amount => BigDecimal.new("11.00"),
              :inherited_from_id => SpecHelper::AddOnIncrease10,
              :quantity => 2,
              :number_of_billing_cycles => 5
            },
            {
              :amount => BigDecimal.new("21.00"),
              :inherited_from_id => SpecHelper::AddOnIncrease20,
              :quantity => 3,
              :number_of_billing_cycles => 6
            }
          ]
        },
        :discounts => {
          :add => [
            {
              :amount => BigDecimal.new("7.50"),
              :inherited_from_id => SpecHelper::Discount7,
              :quantity => 2,
              :never_expires => true
            }
          ]
        }
      )

      result.success?.should be_true
      transaction = result.subscription.transactions.first

      transaction.plan_id.should == SpecHelper::TriallessPlan[:id]

      transaction.add_ons.size.should == 2
      add_ons = transaction.add_ons.sort_by { |add_on| add_on.id }

      add_ons.first.id.should == "increase_10"
      add_ons.first.amount.should == BigDecimal.new("11.00")
      add_ons.first.quantity.should == 2
      add_ons.first.number_of_billing_cycles.should == 5
      add_ons.first.never_expires?.should be_false

      add_ons.last.id.should == "increase_20"
      add_ons.last.amount.should == BigDecimal.new("21.00")
      add_ons.last.quantity.should == 3
      add_ons.last.number_of_billing_cycles.should == 6
      add_ons.last.never_expires?.should be_false

      transaction.discounts.size.should == 1

      transaction.discounts.first.id.should == "discount_7"
      transaction.discounts.first.amount.should == BigDecimal.new("7.50")
      transaction.discounts.first.quantity.should == 2
      transaction.discounts.first.number_of_billing_cycles.should be_nil
      transaction.discounts.first.never_expires?.should be_true
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
            :name => '123*123456789012345678',
            :phone => '3334445555'
          }
        )
        result.success?.should == true
        result.transaction.descriptor.name.should == '123*123456789012345678'
        result.transaction.descriptor.phone.should == '3334445555'
      end

      it "has validation errors if format is invalid" do
        result = Braintree::Transaction.sale(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
          :descriptor => {
            :name => 'badcompanyname12*badproduct12',
            :phone => '%bad4445555'
          }
        )
        result.success?.should == false
        result.errors.for(:transaction).for(:descriptor).on(:name)[0].code.should == Braintree::ErrorCodes::Descriptor::NameFormatIsInvalid
        result.errors.for(:transaction).for(:descriptor).on(:phone)[0].code.should == Braintree::ErrorCodes::Descriptor::PhoneFormatIsInvalid
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
          :tax_amount => '0.05',
          :tax_exempt => false,
          :purchase_order_number => '12345678901234567'
        )
        result.success?.should == true
        result.transaction.tax_amount.should == BigDecimal.new("0.05")
        result.transaction.tax_exempt.should == false
        result.transaction.purchase_order_number.should == '12345678901234567'
      end

      it "accepts tax_amount as a BigDecimal" do
        result = Braintree::Transaction.sale(
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
          :tax_amount => BigDecimal.new('1.99'),
          :tax_exempt => true
        )
        result.success?.should == true
        result.transaction.tax_amount.should == BigDecimal.new("1.99")
        result.transaction.tax_exempt.should == true
        result.transaction.purchase_order_number.should be_nil
      end

      context "validations" do
        it "tax_amount" do
          result = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
            :tax_amount => 'abcd'
          )
          result.success?.should == false
          result.errors.for(:transaction).on(:tax_amount)[0].code.should == Braintree::ErrorCodes::Transaction::TaxAmountFormatIsInvalid
        end

        it "purchase_order_number length" do
          result = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
            :purchase_order_number => 'a' * 18
          )
          result.success?.should == false
          result.errors.for(:transaction).on(:purchase_order_number)[0].code.should == Braintree::ErrorCodes::Transaction::PurchaseOrderNumberIsTooLong
        end

        it "purchase_order_number format" do
          result = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
            :purchase_order_number => "\303\237\303\245\342\210\202"
          )
          result.success?.should == false
          result.errors.for(:transaction).on(:purchase_order_number)[0].code.should == Braintree::ErrorCodes::Transaction::PurchaseOrderNumberIsInvalid
        end
      end
    end

    context "recurring" do
      it "marks a transaction as recurring" do
        result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :credit_card => {
              :number => Braintree::Test::CreditCardNumbers::Visa,
              :expiration_date => "12/12",
            },
            :recurring => true
          )
          result.success?.should == true
          result.transaction.recurring.should == true
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
            :options => { :store_in_vault_on_success => true }
          )
          result.success?.should == true
          result.transaction.vault_customer.last_name.should == "Doe"
          result.transaction.vault_credit_card.masked_number.should == "401288******1881"
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
            :options => { :store_in_vault_on_success => true }
          )
          result.success?.should == false
          result.transaction.vault_customer.should be_nil
          result.transaction.vault_credit_card.should be_nil
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
            :options => { :store_in_vault_on_success => false }
          )
          result.success?.should == true
          result.transaction.vault_customer.should be_nil
          result.transaction.vault_credit_card.should be_nil
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
            :options => { :store_in_vault_on_success => false }
          )
          result.success?.should == false
          result.transaction.vault_customer.should be_nil
          result.transaction.vault_credit_card.should be_nil
        end
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
          :service_fee_amount => "1.00"
        )
        result.success?.should == true
        result.transaction.service_fee_amount.should == BigDecimal.new("1.00")
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
          :service_fee_amount => "1.00"
        )
        result.success?.should == false
        expected_error_code = Braintree::ErrorCodes::Transaction::ServiceFeeAmountNotAllowedOnMasterMerchantAccount
        result.errors.for(:transaction).on(:service_fee_amount)[0].code.should == expected_error_code
      end

      it "raises an error if no service fee is present on a sub merchant account transaction" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :merchant_account_id => SpecHelper::NonDefaultSubMerchantAccountId,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          }
        )
        result.success?.should == false
        expected_error_code = Braintree::ErrorCodes::Transaction::SubMerchantAccountRequiresServiceFeeAmount
        result.errors.for(:transaction).on(:merchant_account_id)[0].code.should == expected_error_code
      end

      it "raises an error if service fee amount is negative" do
        result = Braintree::Transaction.create(
          :merchant_account_id => SpecHelper::NonDefaultSubMerchantAccountId,
          :service_fee_amount => "-1.00"
        )
        result.success?.should == false
        result.errors.for(:transaction).on(:service_fee_amount)[0].code.should == Braintree::ErrorCodes::Transaction::ServiceFeeAmountCannotBeNegative
      end

      it "raises an error if service fee amount is invalid" do
        result = Braintree::Transaction.create(
          :merchant_account_id => SpecHelper::NonDefaultSubMerchantAccountId,
          :service_fee_amount => "invalid amount"
        )
        result.success?.should == false
        result.errors.for(:transaction).on(:service_fee_amount)[0].code.should == Braintree::ErrorCodes::Transaction::ServiceFeeAmountFormatIsInvalid
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
          :options => {:hold_in_escrow => true}
        )

        result.success?.should == true
        result.transaction.escrow_status.should == Braintree::Transaction::EscrowStatus::HoldPending
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
          :options => {:hold_in_escrow => true}
        )
        result.success?.should == false
        expected_error_code = Braintree::ErrorCodes::Transaction::CannotHoldInEscrow
        result.errors.for(:transaction).on(:base)[0].code.should == expected_error_code
      end
    end

    describe "venmo_sdk" do
      it "can create a card with a venmo sdk payment method code" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :venmo_sdk_payment_method_code => Braintree::Test::VenmoSDK::VisaPaymentMethodCode
        )
        result.success?.should == true
        result.transaction.credit_card_details.bin.should == "400934"
        result.transaction.credit_card_details.last_4.should == "1881"
      end

      it "can create a transaction with venmo sdk session" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "12/12",
          },
          :options => {
            :venmo_sdk_session => Braintree::Test::VenmoSDK::Session
          }
        )
        result.success?.should == true
        result.transaction.credit_card_details.venmo_sdk?.should == true
      end
    end

    context "client API" do
      it "can create a credit card transaction with a nonce" do
        nonce = nonce_for_new_credit_card(
          :credit_card => {
            :number => "4111111111111111",
            :expiration_month => "11",
            :expiration_year => "2099",
          },
          :share => true
        )

        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :payment_method_nonce => nonce
        )

        result.success?.should == true
      end
    end

    context "paypal" do
      context "using a vaulted paypal account payment_method_token" do
        it "can create a transaction" do
          payment_method_result = Braintree::PaymentMethod.create(
            :customer_id => Braintree::Customer.create.customer.id,
            :payment_method_nonce => Braintree::Test::Nonce::PayPalFuturePayment
          )
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :payment_method_token => payment_method_result.payment_method.token,
          )

          result.should be_success
        end
      end

      context "future" do
        it "can create a paypal transaction with a nonce without vaulting" do
          payment_method_token = rand(36**3).to_s(36)
          nonce = nonce_for_paypal_account(
            :consent_code => "PAYPAL_CONSENT_CODE",
            :token => payment_method_token
          )

          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :payment_method_nonce => nonce,
          )

          result.should be_success

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

          result.success?.should == true

          found_paypal_account = Braintree::PaymentMethod.find(payment_method_token)
          found_paypal_account.should be_a(Braintree::PayPalAccount)
          found_paypal_account.token.should == payment_method_token
        end
      end

      context "onetime" do
        it "can create a paypal transaction with a nonce" do
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
          )

          result.should be_success
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

          result.success?.should == true

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
            }
          )
          result.success?.should == true
          result.transaction.status.should == Braintree::Transaction::Status::SubmittedForSettlement
        end
      end

      context "void" do
        it "successfully voids a paypal transaction that's been authorized" do
          sale_transaction = Braintree::Transaction.sale!(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
            :options => {
              :submit_for_settlement => true
            }
          )

          void_transaction = Braintree::Transaction.void!(sale_transaction.id)
          void_transaction.should == sale_transaction
          void_transaction.status.should == Braintree::Transaction::Status::Voided
        end

        it "fails to void a paypal transaction that's been declined" do
          sale_transaction = Braintree::Transaction.sale(
            :amount => Braintree::Test::TransactionAmounts::Decline,
            :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
            :options => {
              :submit_for_settlement => true
            }
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
            result.should be_success
            result.transaction.type.should == "credit"
          end

          it "allows multiple partial refunds" do
            transaction = create_paypal_transaction_for_refund

            transaction_1 = Braintree::Transaction.refund(transaction.id, transaction.amount / 2).transaction
            transaction_2 = Braintree::Transaction.refund(transaction.id, transaction.amount / 2).transaction

            transaction = Braintree::Transaction.find(transaction.id)
            transaction.refund_ids.sort.should == [transaction_1.id, transaction_2.id].sort
          end
        end

        it "returns a successful result if successful" do
          transaction = create_paypal_transaction_for_refund

          result = Braintree::Transaction.refund(transaction.id)
          result.success?.should == true
          result.transaction.type.should == "credit"
        end

        it "assigns the refund_id on the original transaction" do
          transaction = create_paypal_transaction_for_refund
          refund_transaction = Braintree::Transaction.refund(transaction.id).transaction
          transaction = Braintree::Transaction.find(transaction.id)

          transaction.refund_id.should == refund_transaction.id
        end

        it "assigns the refunded_transaction_id to the original transaction" do
          transaction = create_paypal_transaction_for_refund
          refund_transaction = Braintree::Transaction.refund(transaction.id).transaction

          refund_transaction.refunded_transaction_id.should == transaction.id
        end

        it "returns an error if already refunded" do
          transaction = create_paypal_transaction_for_refund
          result = Braintree::Transaction.refund(transaction.id)
          result.success?.should == true
          result = Braintree::Transaction.refund(transaction.id)
          result.success?.should == false
          result.errors.for(:transaction).on(:base)[0].code.should == Braintree::ErrorCodes::Transaction::HasAlreadyBeenRefunded
        end

        it "returns an error result if unsettled" do
          transaction = Braintree::Transaction.sale!(
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
            :options => {
              :submit_for_settlement => true
            }
          )
          result = Braintree::Transaction.refund(transaction.id)
          result.success?.should == false
          result.errors.for(:transaction).on(:base)[0].code.should == Braintree::ErrorCodes::Transaction::CannotRefundUnlessSettled
        end
      end

      context "handling errors" do
        it "handles bad unvalidated nonces" do
          nonce = nonce_for_paypal_account(
            :access_token => "PAYPAL_ACCESS_TOKEN",
            :consent_code => "PAYPAL_CONSENT_CODE"
          )

          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :payment_method_nonce => nonce,
          )

          result.should_not be_success
          result.errors.for(:transaction).for(:paypal_account).first.code.should == "82903"
        end

        it "handles non-existent nonces" do
          result = Braintree::Transaction.create(
            :type => "sale",
            :amount => Braintree::Test::TransactionAmounts::Authorize,
            :payment_method_nonce => "NON_EXISTENT_NONCE",
          )

          result.should_not be_success
          result.errors.for(:transaction).first.code.should == "91565"
        end
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
        }
      )
      transaction.id.should =~ /^\w{6}$/
      transaction.type.should == "sale"
      transaction.amount.should == BigDecimal.new(Braintree::Test::TransactionAmounts::Authorize)
      transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      transaction.credit_card_details.expiration_date.should == "05/2009"
    end

    it "raises a validationsfailed if invalid" do
      expect do
        Braintree::Transaction.create!(
          :type => "sale",
          :amount => nil,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        )
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.refund" do
    context "partial refunds" do
      it "allows partial refunds" do
        transaction = create_transaction_to_refund
        result = Braintree::Transaction.refund(transaction.id, transaction.amount / 2)
        result.success?.should == true
        result.transaction.type.should == "credit"
      end

      it "allows multiple partial refunds" do
        transaction = create_transaction_to_refund
        transaction_1 = Braintree::Transaction.refund(transaction.id, transaction.amount / 2).transaction
        transaction_2 = Braintree::Transaction.refund(transaction.id, transaction.amount / 2).transaction

        transaction = Braintree::Transaction.find(transaction.id)
        transaction.refund_ids.sort.should == [transaction_1.id, transaction_2.id].sort
      end
    end

    it "returns a successful result if successful" do
      transaction = create_transaction_to_refund
      transaction.status.should == Braintree::Transaction::Status::Settled
      result = Braintree::Transaction.refund(transaction.id)
      result.success?.should == true
      result.transaction.type.should == "credit"
    end

    it "assigns the refund_id on the original transaction" do
      transaction = create_transaction_to_refund
      refund_transaction = Braintree::Transaction.refund(transaction.id).transaction
      transaction = Braintree::Transaction.find(transaction.id)

      transaction.refund_id.should == refund_transaction.id
    end

    it "assigns the refunded_transaction_id to the original transaction" do
      transaction = create_transaction_to_refund
      refund_transaction = Braintree::Transaction.refund(transaction.id).transaction

      refund_transaction.refunded_transaction_id.should == transaction.id
    end

    it "returns an error if already refunded" do
      transaction = create_transaction_to_refund
      result = Braintree::Transaction.refund(transaction.id)
      result.success?.should == true
      result = Braintree::Transaction.refund(transaction.id)
      result.success?.should == false
      result.errors.for(:transaction).on(:base)[0].code.should == Braintree::ErrorCodes::Transaction::HasAlreadyBeenRefunded
    end

    it "returns an error result if unsettled" do
      transaction = Braintree::Transaction.create!(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      result = Braintree::Transaction.refund(transaction.id)
      result.success?.should == false
      result.errors.for(:transaction).on(:base)[0].code.should == Braintree::ErrorCodes::Transaction::CannotRefundUnlessSettled
    end
  end

  describe "self.refund!" do
    it "returns the refund if valid refund" do
      transaction = create_transaction_to_refund

      refund_transaction = Braintree::Transaction.refund!(transaction.id)

      refund_transaction.refunded_transaction_id.should == transaction.id
      refund_transaction.type.should == "credit"
      transaction.amount.should == refund_transaction.amount
    end

    it "raises a ValidationsFailed if invalid" do
      transaction = create_transaction_to_refund
      invalid_refund_amount = transaction.amount + 1
      invalid_refund_amount.should be > transaction.amount

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
        }
      )
      result.success?.should == true
      result.transaction.id.should =~ /^\w{6}$/
      result.transaction.type.should == "sale"
      result.transaction.amount.should == BigDecimal.new(Braintree::Test::TransactionAmounts::Authorize)
      result.transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      result.transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      result.transaction.credit_card_details.expiration_date.should == "05/2009"
    end

    it "works when given all attributes" do
      result = Braintree::Transaction.sale(
        :amount => "100.00",
        :order_id => "123",
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
          :postal_code => "60103",
          :country_name => "United States of America"
        }
      )
      result.success?.should == true
      transaction = result.transaction
      transaction.id.should =~ /\A\w{6}\z/
      transaction.type.should == "sale"
      transaction.status.should == Braintree::Transaction::Status::Authorized
      transaction.amount.should == BigDecimal.new("100.00")
      transaction.currency_iso_code.should == "USD"
      transaction.order_id.should == "123"
      transaction.channel.should == "MyShoppingCartProvider"
      transaction.processor_response_code.should == "1000"
      transaction.created_at.between?(Time.now - 60, Time.now).should == true
      transaction.updated_at.between?(Time.now - 60, Time.now).should == true
      transaction.credit_card_details.bin.should == "510510"
      transaction.credit_card_details.cardholder_name.should == "The Cardholder"
      transaction.credit_card_details.last_4.should == "5100"
      transaction.credit_card_details.masked_number.should == "510510******5100"
      transaction.credit_card_details.card_type.should == "MasterCard"
      transaction.avs_error_response_code.should == nil
      transaction.avs_postal_code_response_code.should == "M"
      transaction.avs_street_address_response_code.should == "M"
      transaction.cvv_response_code.should == "M"
      transaction.customer_details.first_name.should == "Dan"
      transaction.customer_details.last_name.should == "Smith"
      transaction.customer_details.company.should == "Braintree"
      transaction.customer_details.email.should == "dan@example.com"
      transaction.customer_details.phone.should == "419-555-1234"
      transaction.customer_details.fax.should == "419-555-1235"
      transaction.customer_details.website.should == "http://braintreepayments.com"
      transaction.billing_details.first_name.should == "Carl"
      transaction.billing_details.last_name.should == "Jones"
      transaction.billing_details.company.should == "Braintree"
      transaction.billing_details.street_address.should == "123 E Main St"
      transaction.billing_details.extended_address.should == "Suite 403"
      transaction.billing_details.locality.should == "Chicago"
      transaction.billing_details.region.should == "IL"
      transaction.billing_details.postal_code.should == "60622"
      transaction.billing_details.country_name.should == "United States of America"
      transaction.billing_details.country_code_alpha2.should == "US"
      transaction.billing_details.country_code_alpha3.should == "USA"
      transaction.billing_details.country_code_numeric.should == "840"
      transaction.shipping_details.first_name.should == "Andrew"
      transaction.shipping_details.last_name.should == "Mason"
      transaction.shipping_details.company.should == "Braintree"
      transaction.shipping_details.street_address.should == "456 W Main St"
      transaction.shipping_details.extended_address.should == "Apt 2F"
      transaction.shipping_details.locality.should == "Bartlett"
      transaction.shipping_details.region.should == "IL"
      transaction.shipping_details.postal_code.should == "60103"
      transaction.shipping_details.country_name.should == "United States of America"
      transaction.shipping_details.country_code_alpha2.should == "US"
      transaction.shipping_details.country_code_alpha3.should == "USA"
      transaction.shipping_details.country_code_numeric.should == "840"
    end

    it "allows merchant account to be specified" do
      result = Braintree::Transaction.sale(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      result.success?.should == true
      result.transaction.merchant_account_id.should == SpecHelper::NonDefaultMerchantAccountId
    end

    it "uses default merchant account when it is not specified" do
      result = Braintree::Transaction.sale(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      result.success?.should == true
      result.transaction.merchant_account_id.should == SpecHelper::DefaultMerchantAccountId
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
        }
      )
      result.success?.should == true
      transaction = result.transaction
      transaction.customer_details.id.should =~ /\A\d{6,7}\z/
      transaction.vault_customer.id.should == transaction.customer_details.id
      transaction.credit_card_details.token.should =~ /\A\w{4,5}\z/
      transaction.vault_credit_card.token.should == transaction.credit_card_details.token
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
        }
      )
      result.success?.should == true
      transaction = result.transaction
      transaction.customer_details.id.should =~ /\A\d{6,7}\z/
      transaction.vault_customer.id.should == transaction.customer_details.id
      credit_card = Braintree::CreditCard.find(transaction.vault_credit_card.token)
      transaction.billing_details.id.should == credit_card.billing_address.id
      transaction.vault_billing_address.id.should == credit_card.billing_address.id
      credit_card.billing_address.first_name.should == "Carl"
      credit_card.billing_address.last_name.should == "Jones"
      credit_card.billing_address.company.should == "Braintree"
      credit_card.billing_address.street_address.should == "123 E Main St"
      credit_card.billing_address.extended_address.should == "Suite 403"
      credit_card.billing_address.locality.should == "Chicago"
      credit_card.billing_address.region.should == "IL"
      credit_card.billing_address.postal_code.should == "60622"
      credit_card.billing_address.country_name.should == "United States of America"
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
        }
      )
      result.success?.should == true
      transaction = result.transaction
      transaction.customer_details.id.should =~ /\A\d{6,7}\z/
      transaction.vault_customer.id.should == transaction.customer_details.id
      transaction.vault_shipping_address.id.should == transaction.vault_customer.addresses[0].id
      shipping_address = transaction.vault_customer.addresses[0]
      shipping_address.first_name.should == "Carl"
      shipping_address.last_name.should == "Jones"
      shipping_address.company.should == "Braintree"
      shipping_address.street_address.should == "123 E Main St"
      shipping_address.extended_address.should == "Suite 403"
      shipping_address.locality.should == "Chicago"
      shipping_address.region.should == "IL"
      shipping_address.postal_code.should == "60622"
      shipping_address.country_name.should == "United States of America"
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
        }
      )
      result.success?.should == true
      result.transaction.status.should == Braintree::Transaction::Status::SubmittedForSettlement
    end

    it "can specify the customer id and payment method token" do
      customer_id = "customer_#{rand(10**10)}"
      payment_mehtod_token = "credit_card_#{rand(10**10)}"
      result = Braintree::Transaction.sale(
        :amount => "100",
        :customer => {
          :id => customer_id,
          :first_name => "Adam",
          :last_name => "Williams"
        },
        :credit_card => {
          :token => payment_mehtod_token,
          :number => "5105105105105100",
          :expiration_date => "05/2012"
        },
        :options => {
          :store_in_vault => true
        }
      )
      result.success?.should == true
      transaction = result.transaction
      transaction.customer_details.id.should == customer_id
      transaction.vault_customer.id.should == customer_id
      transaction.credit_card_details.token.should == payment_mehtod_token
      transaction.vault_credit_card.token.should == payment_mehtod_token
    end

    it "can specify existing shipping address" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      address = Braintree::Address.create!(
        :customer_id => customer.id,
        :street_address => '123 Fake St.'
      )
      result = Braintree::Transaction.sale(
        :amount => "100",
        :customer_id => customer.id,
        :shipping_address_id => address.id
      )
      result.success?.should == true
      transaction = result.transaction
      transaction.shipping_details.street_address.should == '123 Fake St.'
      transaction.customer_details.id.should == customer.id
      transaction.shipping_details.id.should == address.id
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
      result.success?.should == false
      result.params.should == {:transaction => {:type => 'sale', :amount => nil, :credit_card => {:expiration_date => "05/2009"}}}
      result.errors.for(:transaction).on(:amount)[0].code.should == Braintree::ErrorCodes::Transaction::AmountIsRequired
    end
  end

  describe "self.sale!" do
    it "returns the transaction if valid" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      transaction.id.should =~ /^\w{6}$/
      transaction.type.should == "sale"
      transaction.amount.should == BigDecimal.new(Braintree::Test::TransactionAmounts::Authorize)
      transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      transaction.credit_card_details.expiration_date.should == "05/2009"
    end

    it "raises a ValidationsFailed if invalid" do
      expect do
        Braintree::Transaction.sale!(
          :amount => nil,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
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
        }
      )
      result = Braintree::Transaction.submit_for_settlement(transaction.id)
      result.success?.should == true
    end

    it "can submit a specific amount for settlement" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      )
      transaction.amount.should == BigDecimal.new("1000.00")
      result = Braintree::Transaction.submit_for_settlement(transaction.id, "999.99")
      result.success?.should == true
      result.transaction.amount.should == BigDecimal.new("999.99")
      result.transaction.status.should == Braintree::Transaction::Status::SubmittedForSettlement
      result.transaction.updated_at.between?(Time.now - 60, Time.now).should == true
    end

    it "returns an error result if settlement is too large" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      )
      transaction.amount.should == BigDecimal.new("1000.00")
      result = Braintree::Transaction.submit_for_settlement(transaction.id, "1000.01")
      result.success?.should == false
      result.errors.for(:transaction).on(:amount)[0].code.should == Braintree::ErrorCodes::Transaction::SettlementAmountIsTooLarge
      result.params[:transaction][:amount].should == "1000.01"
    end

    it "returns an error result if status is not authorized" do
      transaction = Braintree::Transaction.sale(
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      ).transaction
      result = Braintree::Transaction.submit_for_settlement(transaction.id)
      result.success?.should == false
      result.errors.for(:transaction).on(:base)[0].code.should == Braintree::ErrorCodes::Transaction::CannotSubmitForSettlement
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
          :service_fee_amount => "1.00"
        ).transaction
        result = Braintree::Transaction.submit_for_settlement(transaction.id, "0.01")
        result.success?.should == false
        result.errors.for(:transaction).on(:amount)[0].code.should == Braintree::ErrorCodes::Transaction::SettlementAmountIsLessThanServiceFeeAmount
      end
    end
  end

  describe "self.submit_for_settlement!" do
    it "returns the transaction if successful" do
      original_transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      )
      transaction = Braintree::Transaction.submit_for_settlement!(original_transaction.id)
      transaction.status.should == Braintree::Transaction::Status::SubmittedForSettlement
      transaction.id.should == original_transaction.id
    end

    it "raises a ValidationsFailed if unsuccessful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      )
      transaction.amount.should == BigDecimal.new("1000.00")
      expect do
        Braintree::Transaction.submit_for_settlement!(transaction.id, "1000.01")
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.release_from_escrow" do
    it "returns the transaction if successful" do
      original_transaction = create_escrowed_transcation

      result = Braintree::Transaction.release_from_escrow(original_transaction.id)
      result.transaction.escrow_status.should == Braintree::Transaction::EscrowStatus::ReleasePending
    end

    it "returns an error result if escrow_status is not HeldForEscrow" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::NonDefaultSubMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
        :service_fee_amount => '1.00'
      )

      transaction.escrow_status.should be_nil

      result = Braintree::Transaction.release_from_escrow(transaction.id)
      result.errors.for(:transaction).on(:base)[0].code.should == Braintree::ErrorCodes::Transaction::CannotReleaseFromEscrow
    end
  end

  describe "self.release_from_escrow!" do
    it "returns the transaction when successful" do
      original_transaction = create_escrowed_transcation

      transaction = Braintree::Transaction.release_from_escrow!(original_transaction.id)
      transaction.escrow_status.should == Braintree::Transaction::EscrowStatus::ReleasePending
    end

    it "raises an error when transaction is not successful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::NonDefaultSubMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
        :service_fee_amount => '1.00'
      )

      transaction.escrow_status.should be_nil

      expect do
        Braintree::Transaction.release_from_escrow!(transaction.id)
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.cancel_release" do
    it "returns the transaction if successful" do
      transaction = create_escrowed_transcation
      result = Braintree::Transaction.release_from_escrow(transaction.id)
      result.transaction.escrow_status.should == Braintree::Transaction::EscrowStatus::ReleasePending

      result = Braintree::Transaction.cancel_release(transaction.id)

      result.success?.should be_true
      result.transaction.escrow_status.should == Braintree::Transaction::EscrowStatus::Held
    end

    it "returns an error result if escrow_status is not ReleasePending" do
      transaction = create_escrowed_transcation

      result = Braintree::Transaction.cancel_release(transaction.id)

      result.success?.should be_false
      result.errors.for(:transaction).on(:base)[0].code.should == Braintree::ErrorCodes::Transaction::CannotCancelRelease
    end
  end

  describe "self.cancel_release!" do
    it "returns the transaction when release is cancelled" do
      transaction = create_escrowed_transcation
      result = Braintree::Transaction.release_from_escrow(transaction.id)
      result.transaction.escrow_status.should == Braintree::Transaction::EscrowStatus::ReleasePending

      transaction = Braintree::Transaction.cancel_release!(transaction.id)

      transaction.escrow_status.should == Braintree::Transaction::EscrowStatus::Held
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
        }
      )
      result.success?.should == true
      result.transaction.id.should =~ /^\w{6}$/
      result.transaction.type.should == "credit"
      result.transaction.amount.should == BigDecimal.new(Braintree::Test::TransactionAmounts::Authorize)
      result.transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      result.transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      result.transaction.credit_card_details.expiration_date.should == "05/2009"
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
      result.success?.should == false
      result.params.should == {:transaction => {:type => 'credit', :amount => nil, :credit_card => {:expiration_date => "05/2009"}}}
      result.errors.for(:transaction).on(:amount)[0].code.should == Braintree::ErrorCodes::Transaction::AmountIsRequired
    end

    it "allows merchant account to be specified" do
      result = Braintree::Transaction.credit(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      result.success?.should == true
      result.transaction.merchant_account_id.should == SpecHelper::NonDefaultMerchantAccountId
    end

    it "uses default merchant account when it is not specified" do
      result = Braintree::Transaction.credit(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      result.success?.should == true
      result.transaction.merchant_account_id.should == SpecHelper::DefaultMerchantAccountId
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
      result.success?.should == false
      result.errors.for(:transaction).on(:base).map(&:code).should include(Braintree::ErrorCodes::Transaction::ServiceFeeIsNotAllowedOnCredits)
    end
  end

  describe "self.credit!" do
    it "returns the transaction if valid" do
      transaction = Braintree::Transaction.credit!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      transaction.id.should =~ /^\w{6}$/
      transaction.type.should == "credit"
      transaction.amount.should == BigDecimal.new(Braintree::Test::TransactionAmounts::Authorize)
      transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      transaction.credit_card_details.expiration_date.should == "05/2009"
    end

    it "raises a ValidationsFailed if invalid" do
      expect do
        Braintree::Transaction.credit!(
          :amount => nil,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        )
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.create_from_transparent_redirect" do
    it "returns a successful result if successful" do
      params = {
        :transaction => {
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        }
      }
      tr_data_params = {
        :transaction => {
          :type => "sale"
        }
      }
      tr_data = Braintree::TransparentRedirect.transaction_data({:redirect_url => "http://example.com"}.merge(tr_data_params))
      query_string_response = SpecHelper.simulate_form_post_for_tr(tr_data, params, Braintree::Transaction.create_transaction_url)
      result = Braintree::Transaction.create_from_transparent_redirect(query_string_response)

      result.success?.should == true
      transaction = result.transaction
      transaction.type.should == "sale"
      transaction.amount.should == BigDecimal.new("1000.00")
      transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      transaction.credit_card_details.expiration_date.should == "05/2009"
    end

    it "raises an error with a message if given invalid params" do
      params = {
        :transaction => {
          :bad => "value",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        }
      }
      tr_data_params = {
        :transaction => {
          :type => "sale"
        }
      }
      tr_data = Braintree::TransparentRedirect.transaction_data({:redirect_url => "http://example.com"}.merge(tr_data_params))
      query_string_response = SpecHelper.simulate_form_post_for_tr(tr_data, params, Braintree::Transaction.create_transaction_url)

      expect do
        Braintree::Transaction.create_from_transparent_redirect(query_string_response)
      end.to raise_error(Braintree::AuthorizationError, "Invalid params: transaction[bad]")
    end

    it "can put any param in tr_data" do
      params = {

      }
      tr_data_params = {
        :transaction => {
          :amount => "100.00",
          :order_id => "123",
          :channel => "MyShoppingCartProvider",
          :type => "sale",
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
            :postal_code => "60103",
            :country_name => "United States of America"
          }
        }
      }
      tr_data = Braintree::TransparentRedirect.transaction_data({:redirect_url => "http://example.com"}.merge(tr_data_params))
      query_string_response = SpecHelper.simulate_form_post_for_tr(tr_data, params, Braintree::Transaction.create_transaction_url)
      result = Braintree::Transaction.create_from_transparent_redirect(query_string_response)

      transaction = result.transaction
      transaction.id.should =~ /\A\w{6}\z/
      transaction.type.should == "sale"
      transaction.status.should == Braintree::Transaction::Status::Authorized
      transaction.amount.should == BigDecimal.new("100.00")
      transaction.order_id.should == "123"
      transaction.channel.should == "MyShoppingCartProvider"
      transaction.processor_response_code.should == "1000"
      transaction.created_at.between?(Time.now - 60, Time.now).should == true
      transaction.updated_at.between?(Time.now - 60, Time.now).should == true
      transaction.credit_card_details.bin.should == "510510"
      transaction.credit_card_details.last_4.should == "5100"
      transaction.credit_card_details.cardholder_name.should == "The Cardholder"
      transaction.credit_card_details.masked_number.should == "510510******5100"
      transaction.credit_card_details.card_type.should == "MasterCard"
      transaction.avs_error_response_code.should == nil
      transaction.avs_postal_code_response_code.should == "M"
      transaction.avs_street_address_response_code.should == "M"
      transaction.cvv_response_code.should == "M"
      transaction.customer_details.first_name.should == "Dan"
      transaction.customer_details.last_name.should == "Smith"
      transaction.customer_details.company.should == "Braintree"
      transaction.customer_details.email.should == "dan@example.com"
      transaction.customer_details.phone.should == "419-555-1234"
      transaction.customer_details.fax.should == "419-555-1235"
      transaction.customer_details.website.should == "http://braintreepayments.com"
      transaction.billing_details.first_name.should == "Carl"
      transaction.billing_details.last_name.should == "Jones"
      transaction.billing_details.company.should == "Braintree"
      transaction.billing_details.street_address.should == "123 E Main St"
      transaction.billing_details.extended_address.should == "Suite 403"
      transaction.billing_details.locality.should == "Chicago"
      transaction.billing_details.region.should == "IL"
      transaction.billing_details.postal_code.should == "60622"
      transaction.billing_details.country_name.should == "United States of America"
      transaction.shipping_details.first_name.should == "Andrew"
      transaction.shipping_details.last_name.should == "Mason"
      transaction.shipping_details.company.should == "Braintree"
      transaction.shipping_details.street_address.should == "456 W Main St"
      transaction.shipping_details.extended_address.should == "Apt 2F"
      transaction.shipping_details.locality.should == "Bartlett"
      transaction.shipping_details.region.should == "IL"
      transaction.shipping_details.postal_code.should == "60103"
      transaction.shipping_details.country_name.should == "United States of America"
    end

    it "returns an error result if validations fail" do
      params = {
        :transaction => {
          :amount => "",
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        }
      }
      tr_data_params = {
        :transaction => {
          :type => "sale"
        }
      }
      tr_data = Braintree::TransparentRedirect.transaction_data({:redirect_url => "http://example.com"}.merge(tr_data_params))
      query_string_response = SpecHelper.simulate_form_post_for_tr(tr_data, params, Braintree::Transaction.create_transaction_url)
      result = Braintree::Transaction.create_from_transparent_redirect(query_string_response)

      result.success?.should == false
      result.params[:transaction].should == {:amount => "", :type => "sale", :credit_card => {:expiration_date => "05/2009"}}
      result.errors.for(:transaction).on(:amount)[0].code.should == Braintree::ErrorCodes::Transaction::AmountIsRequired
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
        }
      )
      result.success?.should == true
      created_transaction = result.transaction
      found_transaction = Braintree::Transaction.find(created_transaction.id)
      found_transaction.should == created_transaction
    end

    it "raises a NotFoundError exception if transaction cannot be found" do
      expect do
        Braintree::Transaction.find("invalid-id")
      end.to raise_error(Braintree::NotFoundError, 'transaction with id "invalid-id" not found')
    end

    context "disbursement_details" do
      it "includes disbursement_details on found transactions" do
        found_transaction = Braintree::Transaction.find("deposittransaction")

        found_transaction.disbursed?.should == true
        disbursement = found_transaction.disbursement_details

        disbursement.disbursement_date.should == "2013-04-10"
        disbursement.settlement_amount.should == "100.00"
        disbursement.settlement_currency_iso_code.should == "USD"
        disbursement.settlement_currency_exchange_rate.should == "1"
        disbursement.funds_held?.should == false
        disbursement.success?.should be_true
      end

      it "is not disbursed" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        )
        result.success?.should == true
        created_transaction = result.transaction

        created_transaction.disbursed?.should == false
      end
    end

    context "disputes" do
      it "includes disputes on found transactions" do
        found_transaction = Braintree::Transaction.find("disputedtransaction")

        found_transaction.disputes.count.should == 1

        dispute = found_transaction.disputes.first
        dispute.received_date.should == Date.new(2014, 3, 1)
        dispute.reply_by_date.should == Date.new(2014, 3, 21)
        dispute.amount.should == Braintree::Util.to_big_decimal("250.00")
        dispute.currency_iso_code.should == "USD"
        dispute.reason.should == Braintree::Dispute::Reason::Fraud
        dispute.status.should == Braintree::Dispute::Status::Won
      end

      it "is not disputed" do
        result = Braintree::Transaction.create(
          :type => "sale",
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        )
        result.success?.should == true
        created_transaction = result.transaction

        created_transaction.disputes.should == []
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
        :service_fee_amount => "10.00"
      )

      result.transaction.escrow_status.should be_nil
      result = Braintree::Transaction.hold_in_escrow(result.transaction.id)

      result.success?.should be_true
      result.transaction.escrow_status.should == Braintree::Transaction::EscrowStatus::HoldPending
    end

    it "returns an error result if the transaction cannot be held in escrow" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )

      result = Braintree::Transaction.hold_in_escrow(transaction.id)
      result.errors.for(:transaction).on(:base)[0].code.should == Braintree::ErrorCodes::Transaction::CannotHoldInEscrow
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
        :service_fee_amount => "10.00"
      )

      result.transaction.escrow_status.should be_nil
      transaction = Braintree::Transaction.hold_in_escrow!(result.transaction.id)

      transaction.escrow_status.should == Braintree::Transaction::EscrowStatus::HoldPending
    end

    it "raises an error if the transaction cannot be held in escrow" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
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
        }
      )
      result = Braintree::Transaction.void(transaction.id)
      result.success?.should == true
      result.transaction.id.should == transaction.id
      result.transaction.status.should == Braintree::Transaction::Status::Voided
    end

    it "returns an error result if unsuccessful" do
      transaction = Braintree::Transaction.sale(
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      ).transaction
      result = Braintree::Transaction.void(transaction.id)
      result.success?.should == false
      result.errors.for(:transaction).on(:base)[0].code.should == Braintree::ErrorCodes::Transaction::CannotBeVoided
    end
  end

  describe "self.void!" do
    it "returns the transaction if successful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      returned_transaction = Braintree::Transaction.void!(transaction.id)
      returned_transaction.should == transaction
      returned_transaction.status.should == Braintree::Transaction::Status::Voided
    end

    it "raises a ValidationsFailed if unsuccessful" do
      transaction = Braintree::Transaction.sale(
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      ).transaction
      expect do
        Braintree::Transaction.void!(transaction.id)
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "refund" do
    context "partial refunds" do
      it "allows partial refunds" do
        transaction = create_transaction_to_refund
        result = transaction.refund(transaction.amount / 2)
        result.success?.should == true
        result.new_transaction.type.should == "credit"
      end
    end

    it "returns a successful result if successful" do
      transaction = create_transaction_to_refund
      transaction.status.should == Braintree::Transaction::Status::Settled
      result = transaction.refund
      result.success?.should == true
      result.new_transaction.type.should == "credit"
    end

    it "assigns the refund_id on the original transaction" do
      transaction = create_transaction_to_refund
      refund_transaction = transaction.refund.new_transaction
      transaction = Braintree::Transaction.find(transaction.id)

      transaction.refund_id.should == refund_transaction.id
    end

    it "assigns the refunded_transaction_id to the original transaction" do
      transaction = create_transaction_to_refund
      refund_transaction = transaction.refund.new_transaction

      refund_transaction.refunded_transaction_id.should == transaction.id
    end

    it "returns an error if already refunded" do
      transaction = create_transaction_to_refund
      result = transaction.refund
      result.success?.should == true
      result = transaction.refund
      result.success?.should == false
      result.errors.for(:transaction).on(:base)[0].code.should == Braintree::ErrorCodes::Transaction::HasAlreadyBeenRefunded
    end

    it "returns an error result if unsettled" do
      transaction = Braintree::Transaction.create!(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      result = transaction.refund
      result.success?.should == false
      result.errors.for(:transaction).on(:base)[0].code.should == Braintree::ErrorCodes::Transaction::CannotRefundUnlessSettled
    end
  end

  describe "submit_for_settlement" do
    it "returns a successful result if successful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      )
      result = transaction.submit_for_settlement
      result.success?.should == true
    end

    it "can submit a specific amount for settlement" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      )
      transaction.amount.should == BigDecimal.new("1000.00")
      result = transaction.submit_for_settlement("999.99")
      result.success?.should == true
      transaction.amount.should == BigDecimal.new("999.99")
    end

    it "updates the transaction attributes" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      )
      transaction.amount.should == BigDecimal.new("1000.00")
      result = transaction.submit_for_settlement("999.99")
      result.success?.should == true
      transaction.amount.should == BigDecimal.new("999.99")
      transaction.status.should == Braintree::Transaction::Status::SubmittedForSettlement
      transaction.updated_at.between?(Time.now - 60, Time.now).should == true
    end

    it "returns an error result if unsuccessful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      )
      transaction.amount.should == BigDecimal.new("1000.00")
      result = transaction.submit_for_settlement("1000.01")
      result.success?.should == false
      result.errors.for(:transaction).on(:amount)[0].code.should == Braintree::ErrorCodes::Transaction::SettlementAmountIsTooLarge
      result.params[:transaction][:amount].should == "1000.01"
    end
  end

  describe "submit_for_settlement!" do
    it "returns the transaction if successful" do
      original_transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      )
      transaction = original_transaction.submit_for_settlement!
      transaction.status.should == Braintree::Transaction::Status::SubmittedForSettlement
      transaction.id.should == original_transaction.id
    end

    it "raises a ValidationsFailed if unsuccessful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "06/2009"
        }
      )
      transaction.amount.should == BigDecimal.new("1000.00")
      expect do
        transaction.submit_for_settlement!("1000.01")
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
        }
      )
      transaction.submit_for_settlement!
      transaction.status_history.size.should == 2
      transaction.status_history[0].status.should == Braintree::Transaction::Status::Authorized
      transaction.status_history[1].status.should == Braintree::Transaction::Status::SubmittedForSettlement
    end
  end

  describe "vault_credit_card" do
    it "returns the Braintree::CreditCard if the transaction credit card is stored in the vault" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      transaction = customer.credit_cards[0].sale(:amount => "100.00").transaction
      transaction.vault_credit_card.should == customer.credit_cards[0]
    end

    it "returns nil if the transaction credit card is not stored in the vault" do
      transaction = Braintree::Transaction.create!(
        :amount => "100.00",
        :type => "sale",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      transaction.vault_credit_card.should == nil
    end
  end

  describe "vault_customer" do
    it "returns the Braintree::Customer if the transaction customer is stored in the vault" do
      customer = Braintree::Customer.create!(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      transaction = customer.credit_cards[0].sale(:amount => "100.00").transaction
      transaction.vault_customer.should == customer
    end

    it "returns nil if the transaction customer is not stored in the vault" do
      transaction = Braintree::Transaction.create!(
        :amount => "100.00",
        :type => "sale",
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2010"
        }
      )
      transaction.vault_customer.should == nil
    end
  end

  describe "void" do
    it "returns a successful result if successful" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      result.success?.should == true
      transaction = result.transaction
      transaction.status.should == Braintree::Transaction::Status::Authorized
      void_result = transaction.void
      void_result.success?.should == true
      void_result.transaction.should == transaction
      transaction.status.should == void_result.transaction.status
    end

    it "returns an error result if unsuccessful" do
      transaction = Braintree::Transaction.sale(
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      ).transaction
      transaction.status.should == Braintree::Transaction::Status::ProcessorDeclined
      result = transaction.void
      result.success?.should == false
      result.errors.for(:transaction).on(:base)[0].code.should == Braintree::ErrorCodes::Transaction::CannotBeVoided
    end
  end

  describe "void!" do
    it "returns the transaction if successful" do
      transaction = Braintree::Transaction.sale!(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      )
      transaction.void!.should == transaction
      transaction.status.should == Braintree::Transaction::Status::Voided
    end

    it "raises a ValidationsFailed if unsuccessful" do
      transaction = Braintree::Transaction.sale(
        :amount => Braintree::Test::TransactionAmounts::Decline,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        }
      ).transaction
      transaction.status.should == Braintree::Transaction::Status::ProcessorDeclined
      expect do
        transaction.void!
      end.to raise_error(Braintree::ValidationsFailed)
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
      }
    )

    response = Braintree::Configuration.instantiate.http.put "/transactions/#{transaction.id}/settle"
    Braintree::Transaction.find(transaction.id)
  end

  def create_paypal_transaction_for_refund
    transaction = Braintree::Transaction.sale!(
      :amount => Braintree::Test::TransactionAmounts::Authorize,
      :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
      :options => {
        :submit_for_settlement => true
      }
    )

    Braintree::Configuration.instantiate.http.put "/transactions/#{transaction.id}/settle"
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
      :service_fee_amount => '1.00',
      :options => { :hold_in_escrow => true }
    )

    response = Braintree::Configuration.instantiate.http.put "/transactions/#{transaction.id}/settle"
    response = Braintree::Configuration.instantiate.http.put "/transactions/#{transaction.id}/escrow"
    Braintree::Transaction.find(transaction.id)
  end

  context "venmo sdk" do
    describe "venmo_sdk_payment_method_code" do
      it "can create a transaction with venmo_sdk_payment_method_code" do
        result = Braintree::Transaction.sale(
          :amount => "10.00",
          :venmo_sdk_payment_method_code => Braintree::Test::VenmoSDK.generate_test_payment_method_code(Braintree::Test::CreditCardNumbers::Visa)
        )
        result.success?.should == true
        result.transaction.credit_card_details.venmo_sdk?.should == true
      end

      it "errors when an invalid payment method code is passed" do
        result = Braintree::Transaction.sale(
          :amount => "10.00",
          :venmo_sdk_payment_method_code => Braintree::Test::VenmoSDK::InvalidPaymentMethodCode
        )
        result.success?.should == false
        result.message.should == "Invalid VenmoSDK payment method code"
        result.errors.first.code.should == "91727"
      end
    end

    describe "venmo_sdk_session" do
      it "can create a transaction and vault a card when a venmo_sdk_session is present" do
        result = Braintree::Transaction.sale(
          :amount => "10.00",
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
          :options => {
            :venmo_sdk_session => Braintree::Test::VenmoSDK::Session
          }
        )
        result.success?.should == true
        result.transaction.credit_card_details.venmo_sdk?.should == true
      end

      it "venmo_sdk boolean is false when an invalid session is passed" do
        result = Braintree::Transaction.sale(
          :amount => "10.00",
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          },
          :options => {
            :venmo_sdk_session => Braintree::Test::VenmoSDK::InvalidSession
          }
        )
        result.success?.should == true
        result.transaction.credit_card_details.venmo_sdk?.should == false
      end
    end
  end

  context "paypal" do
    it "can create a transaction for a paypal account" do
      result = Braintree::Transaction.sale(
        :amount => "10.00",
        :payment_method_nonce => Braintree::Test::Nonce::PayPalFuturePayment,
      )
      result.success?.should == true
      result.transaction.paypal_details.payer_email.should == "payer@example.com"
      result.transaction.paypal_details.payment_id.should match(/PAY-\w+/)
      result.transaction.paypal_details.authorization_id.should match(/SALE-\w+/)
    end

    it "can vault a paypal account on a transaction" do
      result = Braintree::Transaction.sale(
        :amount => "10.00",
        :payment_method_nonce => Braintree::Test::Nonce::PayPalFuturePayment,
        :options => {
          :store_in_vault => true
        }
      )
      result.success?.should == true
      result.transaction.paypal_details.token.should_not be_nil
      result.transaction.paypal_details.payer_email.should == "payer@example.com"
      result.transaction.paypal_details.payment_id.should match(/PAY-\w+/)
      result.transaction.paypal_details.authorization_id.should match(/SALE-\w+/)
    end

    it "can create a transaction from a vaulted paypal account" do
      customer = Braintree::Customer.create!
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => Braintree::Test::Nonce::PayPalFuturePayment,
        :customer_id => customer.id
      )

      result.should be_success
      result.payment_method.should be_a(Braintree::PayPalAccount)
      payment_method_token = result.payment_method.token

      result = Braintree::Transaction.sale(
        :amount => "100",
        :customer_id => customer.id,
        :payment_method_token => payment_method_token
      )

      result.should be_success
      result.transaction.paypal_details.token.should == payment_method_token
      result.transaction.paypal_details.payer_email.should == "payer@example.com"
      result.transaction.paypal_details.payment_id.should match(/PAY-\w+/)
      result.transaction.paypal_details.authorization_id.should match(/SALE-\w+/)
    end

    context "validation failure" do
      it "returns a validation error if consent code and access token are omitted" do
        nonce = nonce_for_paypal_account(:token => "TOKEN")
        result = Braintree::Transaction.sale(
          :amount => "10.00",
          :payment_method_nonce => nonce,
        )
        result.should_not be_success
        result.errors.for(:transaction).for(:paypal_account).first.code.should == Braintree::ErrorCodes::PayPalAccount::IncompletePayPalAccount
      end
    end
  end
end
