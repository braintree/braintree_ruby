require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::Subscription do

  before(:each) do
    @credit_card = Braintree::Customer.create!(
      :credit_card => {
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2010"
      },
    ).credit_cards[0]
  end

  describe "self.create" do
    it "is successful with a minimum of params" do
      result = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
      )

      expect(result.success?).to eq(true)
      expect(result.subscription.id).to match(/^\w{6}$/)
      expect(result.subscription.status).to eq(Braintree::Subscription::Status::Active)
      expect(result.subscription.plan_id).to eq("integration_trialless_plan")

      expect(result.subscription.first_billing_date).to be_a Date
      expect(result.subscription.next_billing_date).to be_a Date
      expect(result.subscription.billing_period_start_date).to be_a Date
      expect(result.subscription.billing_period_end_date).to be_a Date
      expect(result.subscription.paid_through_date).to be_a Date

      expect(result.subscription.created_at.between?(Time.now - 60, Time.now)).to eq(true)
      expect(result.subscription.updated_at.between?(Time.now - 60, Time.now)).to eq(true)

      expect(result.subscription.failure_count).to eq(0)
      expect(result.subscription.next_billing_period_amount).to eq("12.34")
      expect(result.subscription.payment_method_token).to eq(@credit_card.token)

      expect(result.subscription.status_history.first.price).to eq("12.34")
      expect(result.subscription.status_history.first.status).to eq(Braintree::Subscription::Status::Active)
      expect(result.subscription.status_history.first.subscription_source).to eq(Braintree::Subscription::Source::Api)
      expect(result.subscription.status_history.first.currency_iso_code).to eq("USD")
      expect(result.subscription.status_history.first.plan_id).to eq(SpecHelper::TriallessPlan[:id])
    end

    it "returns a transaction with billing period populated" do
      result = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
      )

      expect(result.success?).to eq(true)
      subscription = result.subscription
      transaction = subscription.transactions.first

      expect(transaction.subscription_details.billing_period_start_date).to eq(subscription.billing_period_start_date)
      expect(transaction.subscription_details.billing_period_end_date).to eq(subscription.billing_period_end_date)
    end

    it "can set the id" do
      new_id = rand(36**9).to_s(36)
      result = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TrialPlan[:id],
        :id => new_id,
      )

      expect(result.success?).to eq(true)
      expect(result.subscription.id).to eq(new_id)
    end

    context "with payment_method_nonces" do
      it "creates a subscription when given a credit card payment_method_nonce" do
        nonce = nonce_for_new_payment_method(
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_month => "11",
            :expiration_year => "2099",
          },
          :client_token_options => {
            :customer_id => @credit_card.customer_id
          },
        )
        result = Braintree::Subscription.create(
          :payment_method_nonce => nonce,
          :plan_id => SpecHelper::TriallessPlan[:id],
        )

        expect(result.success?).to eq(true)
        transaction = result.subscription.transactions[0]
        expect(transaction.credit_card_details.bin).to eq(Braintree::Test::CreditCardNumbers::Visa[0, 6])
        expect(transaction.credit_card_details.last_4).to eq(Braintree::Test::CreditCardNumbers::Visa[-4, 4])
      end

      it "creates a subscription when given a paypal account payment_method_nonce" do
        customer = Braintree::Customer.create!
        payment_method_result = Braintree::PaymentMethod.create(
          :payment_method_nonce => Braintree::Test::Nonce::PayPalBillingAgreement,
          :customer_id => customer.id,
        )

        result = Braintree::Subscription.create(
          :payment_method_token => payment_method_result.payment_method.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
        )

        expect(result).to be_success
        transaction = result.subscription.transactions[0]
        expect(transaction.paypal_details.payer_email).to eq("payer@example.com")
      end

      it "creates a subscription when given a paypal description" do
        customer = Braintree::Customer.create!
        payment_method_result = Braintree::PaymentMethod.create(
          :payment_method_nonce => Braintree::Test::Nonce::PayPalFuturePayment,
          :customer_id => customer.id,
        )

        result = Braintree::Subscription.create(
          :payment_method_token => payment_method_result.payment_method.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :options => {
            :paypal => {
              :description => "A great product",
            },
          },
        )

        expect(result).to be_success
        subscription = result.subscription
        expect(subscription.description).to eq("A great product")
        transaction = subscription.transactions[0]
        expect(transaction.paypal_details.payer_email).to eq("payer@example.com")
        expect(transaction.paypal_details.description).to eq("A great product")
      end

      it "returns an error if the payment_method_nonce hasn't been vaulted" do
        customer = Braintree::Customer.create!
        result = Braintree::Subscription.create(
          :payment_method_nonce => Braintree::Test::Nonce::PayPalFuturePayment,
          :plan_id => SpecHelper::TriallessPlan[:id],
        )

        expect(result).not_to be_success
        expect(result.errors.for(:subscription).on(:payment_method_nonce).first.code).to eq("91925")
      end
    end

    context "billing_day_of_month" do
      it "inherits from the plan if not provided" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::BillingDayOfMonthPlan[:id],
        )

        expect(result.success?).to eq(true)
        expect(result.subscription.billing_day_of_month).to eq(5)
      end

      it "allows overriding" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::BillingDayOfMonthPlan[:id],
          :billing_day_of_month => 25,
        )

        expect(result.success?).to eq(true)
        expect(result.subscription.billing_day_of_month).to eq(25)
      end

      it "allows overriding with start_immediately" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::BillingDayOfMonthPlan[:id],
          :options => {
            :start_immediately => true
          },
        )

        expect(result.success?).to eq(true)
        expect(result.subscription.transactions.size).to eq(1)
      end
    end

    context "first_billing_date" do
      it "allows specifying" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::BillingDayOfMonthPlan[:id],
          :first_billing_date => Date.today + 3,
        )

        expect(result.success?).to eq(true)
        expect(result.subscription.first_billing_date).to eq(Date.today + 3)
        expect(result.subscription.status).to eq(Braintree::Subscription::Status::Pending)
      end

      it "returns an error if the date is in the past" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::BillingDayOfMonthPlan[:id],
          :first_billing_date => Date.today - 3,
        )

        expect(result.success?).to eq(false)
        expect(result.errors.for(:subscription).on(:first_billing_date).first.code).to eq(Braintree::ErrorCodes::Subscription::FirstBillingDateCannotBeInThePast)
      end
    end

    context "merchant_account_id" do
      it "defaults to the default merchant account if no merchant_account_id is provided" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
        )

        expect(result.success?).to eq(true)
        expect(result.subscription.merchant_account_id).to eq(SpecHelper::DefaultMerchantAccountId)
      end

      it "allows setting the merchant_account_id" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,
        )

        expect(result.success?).to eq(true)
        expect(result.subscription.merchant_account_id).to eq(SpecHelper::NonDefaultMerchantAccountId)
      end
    end

    context "number_of_billing_cycles" do
      it "sets the number of billing cycles on the subscription when provided" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :number_of_billing_cycles => 10,
        )

        expect(result.success?).to eq(true)
        expect(result.subscription.number_of_billing_cycles).to eq(10)
      end

      it "sets the number of billing cycles to nil if :never_expires => true" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :never_expires => true,
        )

        expect(result.success?).to eq(true)
        expect(result.subscription.number_of_billing_cycles).to eq(nil)
      end
    end

    context "trial period" do
      context "defaults to the plan's trial period settings" do
        it "with no trial" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => SpecHelper::TriallessPlan[:id],
          )

          expect(result.subscription.trial_period).to eq(false)
          expect(result.subscription.trial_duration).to eq(nil)
          expect(result.subscription.trial_duration_unit).to eq(nil)
        end

        it "with a trial" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => SpecHelper::TrialPlan[:id],
          )

          expect(result.subscription.trial_period).to eq(true)
          expect(result.subscription.trial_duration).to eq(2)
          expect(result.subscription.trial_duration_unit).to eq(Braintree::Subscription::TrialDurationUnit::Day)
        end

        it "can alter the trial period params" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => SpecHelper::TrialPlan[:id],
            :trial_duration => 5,
            :trial_duration_unit => Braintree::Subscription::TrialDurationUnit::Month,
          )

          expect(result.subscription.trial_period).to eq(true)
          expect(result.subscription.trial_duration).to eq(5)
          expect(result.subscription.trial_duration_unit).to eq(Braintree::Subscription::TrialDurationUnit::Month)
        end

        it "can override the trial_period param" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => SpecHelper::TrialPlan[:id],
            :trial_period => false,
          )

          expect(result.subscription.trial_period).to eq(false)
        end

        it "doesn't create a transaction if there's a trial period" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => SpecHelper::TrialPlan[:id],
          )

          expect(result.subscription.transactions.size).to eq(0)
        end
      end

      context "no trial period" do
        it "creates a transaction if no trial period" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => SpecHelper::TriallessPlan[:id],
          )

          expect(result.subscription.transactions.size).to eq(1)
          expect(result.subscription.transactions.first).to be_a(Braintree::Transaction)
          expect(result.subscription.transactions.first.amount).to eq(SpecHelper::TriallessPlan[:price])
          expect(result.subscription.transactions.first.type).to eq(Braintree::Transaction::Type::Sale)
          expect(result.subscription.transactions.first.subscription_id).to eq(result.subscription.id)
        end

        it "does not create the subscription and returns the transaction if the transaction is not successful" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => SpecHelper::TriallessPlan[:id],
            :price => Braintree::Test::TransactionAmounts::Decline,
          )

          expect(result.success?).to be(false)
          expect(result.transaction.status).to eq(Braintree::Transaction::Status::ProcessorDeclined)
          expect(result.message).to eq("Do Not Honor")
        end
      end

      context "price" do
        it "defaults to the plan's price" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => SpecHelper::TrialPlan[:id],
          )

          expect(result.subscription.price).to eq(SpecHelper::TrialPlan[:price])
        end

        it "can be overridden" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => SpecHelper::TrialPlan[:id],
            :price => 98.76,
          )

          expect(result.subscription.price).to eq(BigDecimal("98.76"))
        end
      end
    end

    context "validation errors" do
      it "has validation errors on id" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :id => "invalid token",
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:subscription).on(:id)[0].message).to eq("ID is invalid (use only letters, numbers, '-', and '_').")
      end

      it "has validation errors on duplicate id" do
        duplicate_token = "duplicate_token_#{rand(36**8).to_s(36)}"
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :id => duplicate_token,
        )
        expect(result.success?).to eq(true)

        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :id => duplicate_token,
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:subscription).on(:id)[0].message).to eq("ID has already been taken.")
      end

      it "trial duration required" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :trial_period => true,
          :trial_duration => nil,
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:subscription).on(:trial_duration)[0].message).to eq("Trial Duration is required.")
      end

      it "trial duration unit required" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :trial_period => true,
          :trial_duration => 2,
          :trial_duration_unit => nil,
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:subscription).on(:trial_duration_unit)[0].message).to eq("Trial Duration Unit is invalid.")
      end
    end

    context "add_ons and discounts" do
      it "does not inherit the add_ons and discounts from the plan when do_not_inherit_add_ons_or_discounts is set" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::AddOnDiscountPlan[:id],
          :options => {:do_not_inherit_add_ons_or_discounts => true},
        )
        expect(result.success?).to eq(true)

        subscription = result.subscription

        expect(subscription.add_ons.size).to eq(0)
        expect(subscription.discounts.size).to eq(0)
      end

      it "inherits the add_ons and discounts from the plan when not specified" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::AddOnDiscountPlan[:id],
        )
        expect(result.success?).to eq(true)

        subscription = result.subscription

        expect(subscription.add_ons.size).to eq(2)
        add_ons = subscription.add_ons.sort_by { |add_on| add_on.id }

        expect(add_ons.first.id).to eq("increase_10")
        expect(add_ons.first.amount).to eq(BigDecimal("10.00"))
        expect(add_ons.first.quantity).to eq(1)
        expect(add_ons.first.number_of_billing_cycles).to be_nil
        expect(add_ons.first.never_expires?).to be(true)
        expect(add_ons.first.current_billing_cycle).to eq(0)

        expect(add_ons.last.id).to eq("increase_20")
        expect(add_ons.last.amount).to eq(BigDecimal("20.00"))
        expect(add_ons.last.quantity).to eq(1)
        expect(add_ons.last.number_of_billing_cycles).to be_nil
        expect(add_ons.last.never_expires?).to be(true)
        expect(add_ons.last.current_billing_cycle).to eq(0)

        expect(subscription.discounts.size).to eq(2)
        discounts = subscription.discounts.sort_by { |discount| discount.id }

        expect(discounts.first.id).to eq("discount_11")
        expect(discounts.first.amount).to eq(BigDecimal("11.00"))
        expect(discounts.first.quantity).to eq(1)
        expect(discounts.first.number_of_billing_cycles).to be_nil
        expect(discounts.first.never_expires?).to be(true)
        expect(discounts.first.current_billing_cycle).to eq(0)

        expect(discounts.last.id).to eq("discount_7")
        expect(discounts.last.amount).to eq(BigDecimal("7.00"))
        expect(discounts.last.quantity).to eq(1)
        expect(discounts.last.number_of_billing_cycles).to be_nil
        expect(discounts.last.never_expires?).to be(true)
        expect(discounts.last.current_billing_cycle).to eq(0)
      end

      it "allows overriding of inherited add_ons and discounts" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::AddOnDiscountPlan[:id],
          :add_ons => {
            :update => [
              {
                :amount => BigDecimal("50.00"),
                :existing_id => SpecHelper::AddOnIncrease10,
                :quantity => 2,
                :number_of_billing_cycles => 5
              }
            ]
          },
          :discounts => {
            :update => [
              {
                :amount => BigDecimal("15.00"),
                :existing_id => SpecHelper::Discount7,
                :quantity => 3,
                :never_expires => true
              }
            ]
          },
        )
        expect(result.success?).to eq(true)

        subscription = result.subscription

        expect(subscription.add_ons.size).to eq(2)
        add_ons = subscription.add_ons.sort_by { |add_on| add_on.id }

        expect(add_ons.first.id).to eq("increase_10")
        expect(add_ons.first.amount).to eq(BigDecimal("50.00"))
        expect(add_ons.first.quantity).to eq(2)
        expect(add_ons.first.number_of_billing_cycles).to eq(5)
        expect(add_ons.first.never_expires?).to be(false)
        expect(add_ons.first.current_billing_cycle).to eq(0)

        expect(add_ons.last.id).to eq("increase_20")
        expect(add_ons.last.amount).to eq(BigDecimal("20.00"))
        expect(add_ons.last.quantity).to eq(1)
        expect(add_ons.last.current_billing_cycle).to eq(0)

        expect(subscription.discounts.size).to eq(2)
        discounts = subscription.discounts.sort_by { |discount| discount.id }

        expect(discounts.first.id).to eq("discount_11")
        expect(discounts.first.amount).to eq(BigDecimal("11.00"))
        expect(discounts.first.quantity).to eq(1)
        expect(discounts.first.current_billing_cycle).to eq(0)

        expect(discounts.last.id).to eq("discount_7")
        expect(discounts.last.amount).to eq(BigDecimal("15.00"))
        expect(discounts.last.quantity).to eq(3)
        expect(discounts.last.number_of_billing_cycles).to be_nil
        expect(discounts.last.never_expires?).to be(true)
        expect(discounts.last.current_billing_cycle).to eq(0)
      end

      it "allows deleting of inherited add_ons and discounts" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::AddOnDiscountPlan[:id],
          :add_ons => {
            :remove => [SpecHelper::AddOnIncrease10]
          },
          :discounts => {
            :remove => [SpecHelper::Discount7]
          },
        )
        expect(result.success?).to eq(true)

        subscription = result.subscription

        expect(subscription.add_ons.size).to eq(1)
        expect(subscription.add_ons.first.id).to eq("increase_20")
        expect(subscription.add_ons.first.amount).to eq(BigDecimal("20.00"))
        expect(subscription.add_ons.first.quantity).to eq(1)
        expect(subscription.add_ons.first.current_billing_cycle).to eq(0)

        expect(subscription.discounts.size).to eq(1)
        expect(subscription.discounts.last.id).to eq("discount_11")
        expect(subscription.discounts.last.amount).to eq(BigDecimal("11.00"))
        expect(subscription.discounts.last.quantity).to eq(1)
        expect(subscription.discounts.last.current_billing_cycle).to eq(0)
      end

      it "allows adding new add_ons and discounts" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::AddOnDiscountPlan[:id],
          :add_ons => {
            :add => [{:inherited_from_id => SpecHelper::AddOnIncrease30}]
          },
          :discounts => {
            :add => [{:inherited_from_id => SpecHelper::Discount15}]
          },
        )
        expect(result.success?).to eq(true)
        subscription = result.subscription

        expect(subscription.add_ons.size).to eq(3)
        add_ons = subscription.add_ons.sort_by { |add_on| add_on.id }

        expect(add_ons[0].id).to eq("increase_10")
        expect(add_ons[0].amount).to eq(BigDecimal("10.00"))
        expect(add_ons[0].quantity).to eq(1)

        expect(add_ons[1].id).to eq("increase_20")
        expect(add_ons[1].amount).to eq(BigDecimal("20.00"))
        expect(add_ons[1].quantity).to eq(1)

        expect(add_ons[2].id).to eq("increase_30")
        expect(add_ons[2].amount).to eq(BigDecimal("30.00"))
        expect(add_ons[2].quantity).to eq(1)

        expect(subscription.discounts.size).to eq(3)
        discounts = subscription.discounts.sort_by { |discount| discount.id }

        expect(discounts[0].id).to eq("discount_11")
        expect(discounts[0].amount).to eq(BigDecimal("11.00"))
        expect(discounts[0].quantity).to eq(1)

        expect(discounts[1].id).to eq("discount_15")
        expect(discounts[1].amount).to eq(BigDecimal("15.00"))
        expect(discounts[1].quantity).to eq(1)

        expect(discounts[2].id).to eq("discount_7")
        expect(discounts[2].amount).to eq(BigDecimal("7.00"))
        expect(discounts[2].quantity).to eq(1)
      end

      it "properly parses validation errors for arrays" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::AddOnDiscountPlan[:id],
          :add_ons => {
            :update => [
              {
                :existing_id => SpecHelper::AddOnIncrease10,
                :amount => "invalid"
              },
              {
                :existing_id => SpecHelper::AddOnIncrease20,
                :quantity => -10,
              }
            ]
          },
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:subscription).for(:add_ons).for(:update).for_index(0).on(:amount)[0].code).to eq(Braintree::ErrorCodes::Subscription::Modification::AmountIsInvalid)
        expect(result.errors.for(:subscription).for(:add_ons).for(:update).for_index(1).on(:quantity)[0].code).to eq(Braintree::ErrorCodes::Subscription::Modification::QuantityIsInvalid)
      end
    end

    context "descriptors" do
      it "accepts name and phone and copies them to the transaction" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :descriptor => {
            :name => "123*123456789012345678",
            :phone => "3334445555"
          },
        )

        expect(result.success?).to eq(true)
        expect(result.subscription.descriptor.name).to eq("123*123456789012345678")
        expect(result.subscription.descriptor.phone).to eq("3334445555")

        expect(result.subscription.transactions.size).to eq(1)
        transaction = result.subscription.transactions.first
        expect(transaction.descriptor.name).to eq("123*123456789012345678")
        expect(transaction.descriptor.phone).to eq("3334445555")
      end

      it "has validation errors if format is invalid" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :descriptor => {
            :name => "badcompanyname12*badproduct12",
            :phone => "%bad4445555",
            :url => "12345678901234"
          },
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:subscription).for(:descriptor).on(:name)[0].code).to eq(Braintree::ErrorCodes::Descriptor::NameFormatIsInvalid)
        expect(result.errors.for(:subscription).for(:descriptor).on(:phone)[0].code).to eq(Braintree::ErrorCodes::Descriptor::PhoneFormatIsInvalid)
        expect(result.errors.for(:subscription).for(:descriptor).on(:url)[0].code).to eq(Braintree::ErrorCodes::Descriptor::UrlFormatIsInvalid)
      end
    end
  end

  describe "self.create!" do
    it "returns the subscription if valid" do
      subscription = Braintree::Subscription.create!(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
      )

      expect(subscription.id).to match(/^\w{6}$/)
      expect(subscription.status).to eq(Braintree::Subscription::Status::Active)
      expect(subscription.plan_id).to eq("integration_trialless_plan")

      expect(subscription.first_billing_date).to be_a Date
      expect(subscription.next_billing_date).to be_a Date
      expect(subscription.billing_period_start_date).to be_a Date
      expect(subscription.billing_period_end_date).to be_a Date
      expect(subscription.paid_through_date).to be_a Date

      expect(subscription.failure_count).to eq(0)
      expect(subscription.current_billing_cycle).to eq(1)
      expect(subscription.next_billing_period_amount).to eq("12.34")
      expect(subscription.payment_method_token).to eq(@credit_card.token)
    end

    it "raises a ValidationsFailed if invalid" do
      expect do
        Braintree::Subscription.create!(
          :payment_method_token => @credit_card.token,
          :plan_id => "not_a_plan_id",
        )
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  describe "self.find" do
    it "finds a subscription" do
      result = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TrialPlan[:id],
      )
      expect(result.success?).to eq(true)

      expect(Braintree::Subscription.find(result.subscription.id)).to eq(result.subscription)
    end

    it "raises Braintree::NotFoundError if it cannot find" do
      expect {
        Braintree::Subscription.find("noSuchSubscription")
      }.to raise_error(Braintree::NotFoundError, 'subscription with id "noSuchSubscription" not found')
    end
  end

  describe "self.update" do
    before(:each) do
      @subscription = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :price => 54.32,
        :plan_id => SpecHelper::TriallessPlan[:id],
      ).subscription
    end

    it "allows changing the merchant_account_id" do
      result = Braintree::Subscription.update(@subscription.id,
        :merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,
      )

      expect(result.success?).to eq(true)
      expect(result.subscription.merchant_account_id).to eq(SpecHelper::NonDefaultMerchantAccountId)
    end

    it "allows changing the payment method by payment_method_token" do
      new_credit_card = Braintree::CreditCard.create!(
        :customer_id => @credit_card.customer_id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2010",
      )

      result = Braintree::Subscription.update(@subscription.id,
        :payment_method_token => new_credit_card.token,
      )

      expect(result.subscription.payment_method_token).to eq(new_credit_card.token)
    end

    it "allows changing the payment_method by payment_method_nonce" do
      nonce = nonce_for_new_payment_method(
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::MasterCard,
          :expiration_date => "05/2010"
        },
        :client_token_options => {
          :customer_id => @credit_card.customer_id,
        },
      )

      result = Braintree::Subscription.update(@subscription.id, :payment_method_nonce => nonce)
      expect(result.subscription.transactions[0].credit_card_details.token).to eq(@credit_card.token)
      expect(result.subscription.payment_method_token).not_to eq(@credit_card.token)
    end

    it "allows changing the descriptors" do
      result = Braintree::Subscription.update(@subscription.id,
        :descriptor => {
          :name => "aaa*1234",
          :phone => "3334443333",
          :url => "ebay.com"
        },
      )

      expect(result.success?).to eq(true)
      expect(result.subscription.descriptor.name).to eq("aaa*1234")
      expect(result.subscription.descriptor.phone).to eq("3334443333")
      expect(result.subscription.descriptor.url).to eq("ebay.com")
    end

    it "allows changing the paypal description" do
      customer = Braintree::Customer.create!
      payment_method = Braintree::PaymentMethod.create(
        :payment_method_nonce => Braintree::Test::Nonce::PayPalFuturePayment,
        :customer_id => customer.id,
      ).payment_method

      subscription = Braintree::Subscription.create(
        :payment_method_token => payment_method.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
      ).subscription

      result = Braintree::Subscription.update(
        subscription.id,
        :options => {
          :paypal => {
            :description => "A great product",
          },
        },
      )

      expect(result.success?).to eq(true)
      expect(result.subscription.description).to eq("A great product")
    end

    context "when successful" do
      it "returns a success response with the updated subscription if valid" do
        new_id = rand(36**9).to_s(36)
        result = Braintree::Subscription.update(@subscription.id,
          :id => new_id,
          :price => 9999.88,
          :plan_id => SpecHelper::TrialPlan[:id],
        )

        expect(result.success?).to eq(true)
        expect(result.subscription.id).to match(/#{new_id}/)
        expect(result.subscription.plan_id).to eq(SpecHelper::TrialPlan[:id])
        expect(result.subscription.price).to eq(BigDecimal("9999.88"))
      end

      context "proration" do
        it "prorates if there is a charge (because merchant has proration option enabled in control panel)" do
          result = Braintree::Subscription.update(@subscription.id,
            :price => @subscription.price.to_f + 1,
          )

          expect(result.success?).to eq(true)
          expect(result.subscription.price.to_f).to eq(@subscription.price.to_f + 1)
          expect(result.subscription.transactions.size).to eq(@subscription.transactions.size + 1)
        end

        it "allows the user to force proration if there is a charge" do
          result = Braintree::Subscription.update(@subscription.id,
            :price => @subscription.price.to_f + 1,
            :options => {:prorate_charges => true},
          )

          expect(result.success?).to eq(true)
          expect(result.subscription.price.to_f).to eq(@subscription.price.to_f + 1)
          expect(result.subscription.transactions.size).to eq(@subscription.transactions.size + 1)
        end

        it "allows the user to prevent proration if there is a charge" do
          result = Braintree::Subscription.update(@subscription.id,
            :price => @subscription.price.to_f + 1,
            :options => {:prorate_charges => false},
          )

          expect(result.success?).to eq(true)
          expect(result.subscription.price.to_f).to eq(@subscription.price.to_f + 1)
          expect(result.subscription.transactions.size).to eq(@subscription.transactions.size)
        end

        it "doesn't prorate if price decreases" do
          result = Braintree::Subscription.update(@subscription.id,
            :price => @subscription.price.to_f - 1,
          )

          expect(result.success?).to eq(true)
          expect(result.subscription.price.to_f).to eq(@subscription.price.to_f - 1)
          expect(result.subscription.transactions.size).to eq(@subscription.transactions.size)
        end

        it "updates the subscription if the proration fails and revert_subscription_on_proration_failure => false" do
          result = Braintree::Subscription.update(@subscription.id,
            :price => @subscription.price.to_f + 2100,
            :options => {
              :revert_subscription_on_proration_failure => false
            },
          )

          expect(result.success?).to eq(true)
          expect(result.subscription.price.to_f).to eq(@subscription.price.to_f + 2100)

          expect(result.subscription.transactions.size).to eq(@subscription.transactions.size + 1)
          transaction = result.subscription.transactions.first
          expect(transaction.status).to eq(Braintree::Transaction::Status::ProcessorDeclined)
          expect(result.subscription.balance).to eq(transaction.amount)
        end

        it "does not update the subscription if the proration fails and revert_subscription_on_proration_failure => true" do
          result = Braintree::Subscription.update(@subscription.id,
            :price => @subscription.price.to_f + 2100,
            :options => {
              :revert_subscription_on_proration_failure => true
            },
          )

          expect(result.success?).to eq(false)
          expect(result.subscription.price.to_f).to eq(@subscription.price.to_f)

          expect(result.subscription.transactions.size).to eq(@subscription.transactions.size + 1)
          transaction = result.subscription.transactions.first
          expect(transaction.status).to eq(Braintree::Transaction::Status::ProcessorDeclined)
          expect(result.subscription.balance).to eq(0)
        end
      end
    end

    context "when unsuccessful" do
      before(:each) do
        @subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
        ).subscription
      end

      it "raises NotFoundError if the subscription can't be found" do
        expect {
          Braintree::Subscription.update(rand(36**9).to_s(36),
            :price => 58.20,
          )
        }.to raise_error(Braintree::NotFoundError)
      end

      it "has validation errors on id" do
        result = Braintree::Subscription.update(@subscription.id, :id => "invalid token")
        expect(result.success?).to eq(false)
        expect(result.errors.for(:subscription).on(:id)[0].code).to eq(Braintree::ErrorCodes::Subscription::TokenFormatIsInvalid)
      end

      it "has a price" do
        result = Braintree::Subscription.update(@subscription.id, :price => "")
        expect(result.success?).to eq(false)
        expect(result.errors.for(:subscription).on(:price)[0].code).to eq(Braintree::ErrorCodes::Subscription::PriceCannotBeBlank)
      end

      it "has a properly formatted price" do
        result = Braintree::Subscription.update(@subscription.id, :price => "9.2.1 apples")
        expect(result.success?).to eq(false)
        expect(result.errors.for(:subscription).on(:price)[0].code).to eq(Braintree::ErrorCodes::Subscription::PriceFormatIsInvalid)
      end

      it "has validation errors on duplicate id" do
        duplicate_id = "new_id_#{rand(36**6).to_s(36)}"
        duplicate = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :id => duplicate_id,
        )
        result = Braintree::Subscription.update(
          @subscription.id,
          :id => duplicate_id,
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:subscription).on(:id)[0].code).to eq(Braintree::ErrorCodes::Subscription::IdIsInUse)
      end

      it "cannot update a canceled subscription" do
        subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :price => 54.32,
          :plan_id => SpecHelper::TriallessPlan[:id],
        ).subscription

        result = Braintree::Subscription.cancel(subscription.id)
        expect(result.success?).to eq(true)

        result = Braintree::Subscription.update(subscription.id,
          :price => 123.45,
        )
        expect(result.success?).to eq(false)
        expect(result.errors.for(:subscription)[0].code).to eq(Braintree::ErrorCodes::Subscription::CannotEditCanceledSubscription)
      end
    end

    context "number_of_billing_cycles" do
      it "sets the number of billing cycles on the subscription when provided" do
        subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :number_of_billing_cycles => 10,
        ).subscription

        result = Braintree::Subscription.update(
          subscription.id,
          :number_of_billing_cycles => 5,
        )

        expect(result.subscription.number_of_billing_cycles).to eq(5)
      end

      it "sets the number of billing cycles to nil if :never_expires => true" do
        subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :number_of_billing_cycles => 10,
        ).subscription

        result = Braintree::Subscription.update(
          subscription.id,
          :never_expires => true,
        )

        expect(result.success?).to eq(true)
        expect(result.subscription.number_of_billing_cycles).to eq(nil)
        expect(result.subscription.never_expires?).to be(true)
      end
    end

    context "add_ons and discounts" do
      it "can update add_ons and discounts" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::AddOnDiscountPlan[:id],
        )
        expect(result.success?).to eq(true)
        subscription = result.subscription

        result = Braintree::Subscription.update(
          subscription.id,
          :add_ons => {
            :update => [
              {
                :existing_id => subscription.add_ons.first.id,
                :amount => BigDecimal("99.99"),
                :quantity => 12
              }
            ]
          },
          :discounts => {
            :update => [
              {
                :existing_id => subscription.discounts.first.id,
                :amount => BigDecimal("88.88"),
                :quantity => 9
              }
            ]
          },
        )

        subscription = result.subscription

        expect(subscription.add_ons.size).to eq(2)
        add_ons = subscription.add_ons.sort_by { |add_on| add_on.id }

        expect(add_ons.first.amount).to eq(BigDecimal("99.99"))
        expect(add_ons.first.quantity).to eq(12)

        expect(subscription.discounts.size).to eq(2)
        discounts = subscription.discounts.sort_by { |discount| discount.id }

        expect(discounts.last.amount).to eq(BigDecimal("88.88"))
        expect(discounts.last.quantity).to eq(9)
      end

      it "allows adding new add_ons and discounts" do
        subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::AddOnDiscountPlan[:id],
        ).subscription

        result = Braintree::Subscription.update(subscription.id,
          :add_ons => {
            :add => [{:inherited_from_id => SpecHelper::AddOnIncrease30}]
          },
          :discounts => {
            :add => [{:inherited_from_id => SpecHelper::Discount15}]
          },
        )

        expect(result.success?).to eq(true)
        subscription = result.subscription

        expect(subscription.add_ons.size).to eq(3)
        add_ons = subscription.add_ons.sort_by { |add_on| add_on.id }

        expect(add_ons[0].id).to eq("increase_10")
        expect(add_ons[0].amount).to eq(BigDecimal("10.00"))
        expect(add_ons[0].quantity).to eq(1)

        expect(add_ons[1].id).to eq("increase_20")
        expect(add_ons[1].amount).to eq(BigDecimal("20.00"))
        expect(add_ons[1].quantity).to eq(1)

        expect(add_ons[2].id).to eq("increase_30")
        expect(add_ons[2].amount).to eq(BigDecimal("30.00"))
        expect(add_ons[2].quantity).to eq(1)

        expect(subscription.discounts.size).to eq(3)
        discounts = subscription.discounts.sort_by { |discount| discount.id }

        expect(discounts[0].id).to eq("discount_11")
        expect(discounts[0].amount).to eq(BigDecimal("11.00"))
        expect(discounts[0].quantity).to eq(1)

        expect(discounts[1].id).to eq("discount_15")
        expect(discounts[1].amount).to eq(BigDecimal("15.00"))
        expect(discounts[1].quantity).to eq(1)

        expect(discounts[2].id).to eq("discount_7")
        expect(discounts[2].amount).to eq(BigDecimal("7.00"))
        expect(discounts[2].quantity).to eq(1)
      end

      it "allows replacing entire set of add_ons and discounts" do
        subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::AddOnDiscountPlan[:id],
        ).subscription

        result = Braintree::Subscription.update(subscription.id,
          :add_ons => {
            :add => [{:inherited_from_id => SpecHelper::AddOnIncrease30}]
          },
          :discounts => {
            :add => [{:inherited_from_id => SpecHelper::Discount15}]
          },
          :options => {:replace_all_add_ons_and_discounts => true},
        )

        expect(result.success?).to eq(true)
        subscription = result.subscription

        expect(subscription.add_ons.size).to eq(1)

        expect(subscription.add_ons[0].amount).to eq(BigDecimal("30.00"))
        expect(subscription.add_ons[0].quantity).to eq(1)

        expect(subscription.discounts.size).to eq(1)

        expect(subscription.discounts[0].amount).to eq(BigDecimal("15.00"))
        expect(subscription.discounts[0].quantity).to eq(1)
      end

      it "allows deleting of add_ons and discounts" do
        subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::AddOnDiscountPlan[:id],
        ).subscription

        result = Braintree::Subscription.update(subscription.id,
          :add_ons => {
            :remove => [SpecHelper::AddOnIncrease10]
          },
          :discounts => {
            :remove => [SpecHelper::Discount7]
          },
        )
        expect(result.success?).to eq(true)

        subscription = result.subscription

        expect(subscription.add_ons.size).to eq(1)
        expect(subscription.add_ons.first.amount).to eq(BigDecimal("20.00"))
        expect(subscription.add_ons.first.quantity).to eq(1)

        expect(subscription.discounts.size).to eq(1)
        expect(subscription.discounts.last.amount).to eq(BigDecimal("11.00"))
        expect(subscription.discounts.last.quantity).to eq(1)
      end
    end
  end

  describe "self.update!" do
    before(:each) do
      @subscription = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :price => 54.32,
        :plan_id => SpecHelper::TriallessPlan[:id],
      ).subscription
    end

    it "returns the updated subscription if valid" do
      new_id = rand(36**9).to_s(36)
      subscription = Braintree::Subscription.update!(@subscription.id,
        :id => new_id,
        :price => 9999.88,
        :plan_id => SpecHelper::TrialPlan[:id],
      )

      expect(subscription.id).to match(/#{new_id}/)
      expect(subscription.plan_id).to eq(SpecHelper::TrialPlan[:id])
      expect(subscription.price).to eq(BigDecimal("9999.88"))
    end

    it "raises a ValidationsFailed if invalid" do
      expect do
        Braintree::Subscription.update!(@subscription.id,
          :plan_id => "not_a_plan_id",
        )
      end.to raise_error(Braintree::ValidationsFailed)
    end

  end

  describe "self.cancel" do
    it "returns a success response with the updated subscription if valid" do
      subscription = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :price => 54.32,
        :plan_id => SpecHelper::TriallessPlan[:id],
      ).subscription

      result = Braintree::Subscription.cancel(subscription.id)
      expect(result.success?).to eq(true)
      expect(result.subscription.status).to eq(Braintree::Subscription::Status::Canceled)
    end

    it "returns a validation error if record not found" do
      expect {
        r = Braintree::Subscription.cancel("noSuchSubscription")
      }.to raise_error(Braintree::NotFoundError, 'subscription with id "noSuchSubscription" not found')
    end

    it "cannot be canceled if already canceled" do
      subscription = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :price => 54.32,
        :plan_id => SpecHelper::TriallessPlan[:id],
      ).subscription

      result = Braintree::Subscription.cancel(subscription.id)
      expect(result.success?).to eq(true)
      expect(result.subscription.status).to eq(Braintree::Subscription::Status::Canceled)

      result = Braintree::Subscription.cancel(subscription.id)
      expect(result.success?).to eq(false)
      expect(result.errors.for(:subscription)[0].code).to eq("81905")
    end
  end

  describe "self.cancel!" do
    it "returns a updated subscription if valid" do
      subscription = Braintree::Subscription.create!(
        :payment_method_token => @credit_card.token,
        :price => 54.32,
        :plan_id => SpecHelper::TriallessPlan[:id],
      )

      updated_subscription = Braintree::Subscription.cancel!(subscription.id)
      expect(updated_subscription.status).to eq(Braintree::Subscription::Status::Canceled)
    end
  end

  describe "self.search" do
    describe "in_trial_period" do
      it "works in the affirmative" do
        id = rand(36**8).to_s(36)
        subscription_with_trial = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :id => "subscription1_#{id}",
        ).subscription

        subscription_without_trial = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :id => "subscription2_#{id}",
        ).subscription

        subscriptions_in_trial_period = Braintree::Subscription.search do |search|
          search.in_trial_period.is true
        end

        expect(subscriptions_in_trial_period).to include(subscription_with_trial)
        expect(subscriptions_in_trial_period).not_to include(subscription_without_trial)

        subscriptions_not_in_trial_period = Braintree::Subscription.search do |search|
          search.in_trial_period.is false
        end

        expect(subscriptions_not_in_trial_period).not_to include(subscription_with_trial)
        expect(subscriptions_not_in_trial_period).to include(subscription_without_trial)
      end
    end

    describe "search on merchant account id" do
      it "searches on merchant_account_id" do
        id = rand(36**8).to_s(36)
        subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :id => "subscription1_#{id}",
          :price => "11.38",
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.merchant_account_id.is subscription.merchant_account_id
          search.price.is "11.38"
        end

        # not testing for specific number since the
        # create subscriptions accumulate over time
        expect(collection.maximum_size).to be >= 1

        collection = Braintree::Subscription.search do |search|
          search.merchant_account_id.in subscription.merchant_account_id, "bogus_merchant_account_id"
          search.price.is "11.38"
        end

        expect(collection.maximum_size).to be >= 1

        collection = Braintree::Subscription.search do |search|
          search.merchant_account_id.is "bogus_merchant_account_id"
          search.price.is "11.38"
        end

        expect(collection.maximum_size).to eq(0)
      end
    end

    describe "id" do
      it "works using the is operator" do
        id = rand(36**8).to_s(36)
        subscription1 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :id => "subscription1_#{id}",
        ).subscription

        subscription2 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :id => "subscription2_#{id}",
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.id.is "subscription1_#{id}"
        end

        expect(collection).to include(subscription1)
        expect(collection).not_to include(subscription2)
      end
    end

    describe "merchant_account_id" do
      it "is searchable using the is or in operator" do
        subscription1 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :merchant_account_id => SpecHelper::DefaultMerchantAccountId,
          :price => "1",
        ).subscription

        subscription2 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,
          :price => "1",
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.merchant_account_id.is SpecHelper::DefaultMerchantAccountId
          search.price.is "1"
        end

        expect(collection).to include(subscription1)
        expect(collection).not_to include(subscription2)

        collection = Braintree::Subscription.search do |search|
          search.merchant_account_id.in [SpecHelper::DefaultMerchantAccountId, SpecHelper::NonDefaultMerchantAccountId]
          search.price.is "1"
        end

        expect(collection).to include(subscription1)
        expect(collection).to include(subscription2)
      end
    end

    describe "plan_id" do
      it "works using the is operator" do
        trialless_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :price => "2",
        ).subscription

        trial_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :price => "2",
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.plan_id.is SpecHelper::TriallessPlan[:id]
          search.price.is "2"
        end

        expect(collection).to include(trialless_subscription)
        expect(collection).not_to include(trial_subscription)
      end
    end

    describe "price" do
      it "works using the is operator" do
        subscription_500 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :price => "5.00",
        ).subscription

        subscription_501 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :price => "5.01",
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.price.is "5.00"
        end

        expect(collection).to include(subscription_500)
        expect(collection).not_to include(subscription_501)
      end
    end

    describe "days_past_due" do
      it "is backwards-compatible for 'is'" do
        active_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :price => "6",
        ).subscription

        past_due_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :price => "6",
        ).subscription

        SpecHelper.make_past_due(past_due_subscription, 5)

        collection = Braintree::Subscription.search do |search|
          search.price.is "6.00"
          search.days_past_due.is 5
        end

        expect(collection).to include(past_due_subscription)
        expect(collection).not_to include(active_subscription)
        collection.each do |s|
          expect(s.status).to eq(Braintree::Subscription::Status::PastDue)
          expect(s.balance).to eq(BigDecimal("6.00"))
        end
      end

      it "passes a smoke test" do
        subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.days_past_due.between 1, 20
        end

        expect(collection).not_to include(subscription)
        collection.each do |s|
          expect(s.days_past_due).to be >= 1
          expect(s.days_past_due).to be <= 20
        end
      end
    end

    describe "billing_cycles_remaining" do
      it "passes a smoke test" do
        subscription_5 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :number_of_billing_cycles => 5,
        ).subscription

        subscription_9 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :number_of_billing_cycles => 10,
        ).subscription

        subscription_15 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :number_of_billing_cycles => 15,
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.billing_cycles_remaining.between 5, 10
        end

        expect(collection).to include(subscription_5)
        expect(collection).to include(subscription_9)
        expect(collection).not_to include(subscription_15)
      end
    end

    describe "transaction_id" do
      it "returns matching results" do
        matching_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
        ).subscription

        non_matching_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.transaction_id.is matching_subscription.transactions.first.id
        end

        expect(collection).to include(matching_subscription)
        expect(collection).not_to include(non_matching_subscription)
      end
    end

    describe "next_billing_date" do
      it "returns matching results" do
        matching_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
        ).subscription

        non_matching_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
        ).subscription

        five_days_from_now = Time.now + (5 * 24 * 60 * 60)
        collection = Braintree::Subscription.search do |search|
          search.next_billing_date >= five_days_from_now
        end

        expect(collection).to include(matching_subscription)
        expect(collection).not_to include(non_matching_subscription)
      end
    end

    context "created_at" do
      before(:each) do
        @subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
        ).subscription
        @created_at = @subscription.created_at
      end

      it "searches on created_at in UTC using between" do
        expect(@created_at).to be_utc

        collection = Braintree::Subscription.search do |search|
          search.id.is @subscription.id
          search.created_at.between(
            @created_at - 60,
            @created_at + 60,
          )
        end

        expect(collection.maximum_size).to eq(1)
        expect(collection.first.id).to eq(@subscription.id)
      end

      it "searches on created_at in UTC using geq" do
        collection = Braintree::Subscription.search do |search|
          search.id.is @subscription.id
          search.created_at >= @created_at - 1
        end

        expect(collection.maximum_size).to eq(1)
        expect(collection.first.id).to eq(@subscription.id)
      end

      it "searches on created_at in UTC using leq" do
        collection = Braintree::Subscription.search do |search|
          search.id.is @subscription.id
          search.created_at <= @created_at + 1
        end

        expect(collection.maximum_size).to eq(1)
        expect(collection.first.id).to eq(@subscription.id)
      end

      it "searches on created_at in UTC and finds nothing" do
        collection = Braintree::Subscription.search do |search|
          search.id.is @subscription.id
          search.created_at.between(
            @created_at + 300,
            @created_at + 400,
          )
        end

        expect(collection.maximum_size).to eq(0)
      end

      it "searches on created_at in UTC using exact time" do
        collection = Braintree::Subscription.search do |search|
          search.id.is @subscription.id
          search.created_at.is @created_at
        end

        expect(collection.maximum_size).to eq(1)
        expect(collection.first.id).to eq(@subscription.id)
      end

      it "searches on created_at in local time using between" do
        now = Time.now

        collection = Braintree::Subscription.search do |search|
          search.id.is @subscription.id
          search.created_at.between(
            now - 60,
            now + 60,
          )
        end

        expect(collection.maximum_size).to eq(1)
        expect(collection.first.id).to eq(@subscription.id)
      end

      it "searches on created_at in local time using geq" do
        now = Time.now

        collection = Braintree::Subscription.search do |search|
          search.id.is @subscription.id
          search.created_at >= now - 60
        end

        expect(collection.maximum_size).to eq(1)
        expect(collection.first.id).to eq(@subscription.id)
      end

      it "searches on created_at in local time using leq" do
        now = Time.now

        collection = Braintree::Subscription.search do |search|
          search.id.is @subscription.id
          search.created_at <= now + 60
        end

        expect(collection.maximum_size).to eq(1)
        expect(collection.first.id).to eq(@subscription.id)
      end

      it "searches on created_at in local time and finds nothing" do
        now = Time.now

        collection = Braintree::Subscription.search do |search|
          search.id.is @subscription.id
          search.created_at.between(
            now + 300,
            now + 400,
          )
        end

        expect(collection.maximum_size).to eq(0)
      end

      it "searches on created_at with dates" do
        collection = Braintree::Subscription.search do |search|
          search.id.is @subscription.id
          search.created_at.between(
            Date.today - 1,
            Date.today + 1,
          )
        end

        expect(collection.maximum_size).to eq(1)
        expect(collection.first.id).to eq(@subscription.id)
      end
    end

    it "returns multiple results" do
      (110 - Braintree::Subscription.search.maximum_size).times do
        Braintree::Subscription.create(:payment_method_token => @credit_card.token, :plan_id => SpecHelper::TrialPlan[:id])
      end

      collection = Braintree::Subscription.search
      expect(collection.maximum_size).to be > 100

      subscriptions_ids = collection.map { |t| t.id }.uniq.compact
      expect(subscriptions_ids.size).to eq(collection.maximum_size)
    end
  end

  describe "self.retry_charge" do
    it "is successful with only subscription id" do
      subscription = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
      ).subscription
      SpecHelper.make_past_due(subscription)

      result = Braintree::Subscription.retry_charge(subscription.id)

      expect(result.success?).to eq(true)
      transaction = result.transaction

      expect(transaction.amount).to eq(subscription.price)
      expect(transaction.processor_authorization_code).not_to be_nil
      expect(transaction.type).to eq(Braintree::Transaction::Type::Sale)
      expect(transaction.status).to eq(Braintree::Transaction::Status::Authorized)
    end

    it "is successful with subscription id and amount" do
      subscription = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
      ).subscription
      SpecHelper.make_past_due(subscription)

      result = Braintree::Subscription.retry_charge(subscription.id, Braintree::Test::TransactionAmounts::Authorize)

      expect(result.success?).to eq(true)
      transaction = result.transaction

      expect(transaction.amount).to eq(BigDecimal(Braintree::Test::TransactionAmounts::Authorize))
      expect(transaction.processor_authorization_code).not_to be_nil
      expect(transaction.type).to eq(Braintree::Transaction::Type::Sale)
      expect(transaction.status).to eq(Braintree::Transaction::Status::Authorized)
    end

    it "is successful with subscription id and submit_for_settlement" do
      subscription = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
      ).subscription
      SpecHelper.make_past_due(subscription)

      result = Braintree::Subscription.retry_charge(subscription.id, Braintree::Test::TransactionAmounts::Authorize, true)

      expect(result.success?).to eq(true)
      transaction = result.transaction

      expect(transaction.amount).to eq(BigDecimal(Braintree::Test::TransactionAmounts::Authorize))
      expect(transaction.processor_authorization_code).not_to be_nil
      expect(transaction.type).to eq(Braintree::Transaction::Type::Sale)
      expect(transaction.status).to eq(Braintree::Transaction::Status::SubmittedForSettlement)
    end

    it "is successful with subscription id, amount and submit_for_settlement" do
      subscription = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
      ).subscription
      SpecHelper.make_past_due(subscription)

      result = Braintree::Subscription.retry_charge(subscription.id, Braintree::Test::TransactionAmounts::Authorize, true)

      expect(result.success?).to eq(true)
      transaction = result.transaction

      expect(transaction.amount).to eq(BigDecimal(Braintree::Test::TransactionAmounts::Authorize))
      expect(transaction.processor_authorization_code).not_to be_nil
      expect(transaction.type).to eq(Braintree::Transaction::Type::Sale)
      expect(transaction.status).to eq(Braintree::Transaction::Status::SubmittedForSettlement)
    end
  end
end
