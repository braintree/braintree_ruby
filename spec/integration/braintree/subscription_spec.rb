require File.dirname(__FILE__) + "/../spec_helper"

describe Braintree::Subscription do

  before(:each) do
    @credit_card = Braintree::Customer.create!(
      :credit_card => {
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2010"
      }
    ).credit_cards[0]
  end

  describe "self.create" do
    it "is successful with a miniumum of params" do
      result = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id]
      )

      date_format = /^\d{4}\D\d{1,2}\D\d{1,2}$/
      result.success?.should == true
      result.subscription.id.should =~ /^\w{6}$/
      result.subscription.status.should == Braintree::Subscription::Status::Active
      result.subscription.plan_id.should == "integration_trialless_plan"

      result.subscription.first_billing_date.should match(date_format)
      result.subscription.next_billing_date.should match(date_format)
      result.subscription.billing_period_start_date.should match(date_format)
      result.subscription.billing_period_end_date.should match(date_format)

      result.subscription.failure_count.should == 0
      result.subscription.next_bill_amount.should == "12.34"
      result.subscription.payment_method_token.should == @credit_card.token
    end

    it "can set the id" do
      new_id = rand(36**9).to_s(36)
      result = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TrialPlan[:id],
        :id => new_id
      )

      date_format = /^\d{4}\D\d{1,2}\D\d{1,2}$/
      result.success?.should == true
      result.subscription.id.should == new_id
    end

    context "billing_day_of_month" do
      it "inherits from the plan if not provided" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::BillingDayOfMonthPlan[:id]
        )

        result.success?.should == true
        result.subscription.billing_day_of_month.should == 5
      end

      it "allows overriding" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::BillingDayOfMonthPlan[:id],
          :billing_day_of_month => 25
        )

        result.success?.should == true
        result.subscription.billing_day_of_month.should == 25
      end

      it "allows overriding with start_immediately" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::BillingDayOfMonthPlan[:id],
          :options => {
            :start_immediately => true
          }
        )

        result.success?.should == true
        result.subscription.transactions.size.should == 1
      end
    end

    context "first_billing_date" do
      it "allows specifying" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::BillingDayOfMonthPlan[:id],
          :first_billing_date => Date.today + 3
        )

        result.success?.should == true
        result.subscription.first_billing_date.should == (Date.today + 3).to_s
        result.subscription.status.should == Braintree::Subscription::Status::Pending
      end

      it "returns an error if the date is in the past" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::BillingDayOfMonthPlan[:id],
          :first_billing_date => Date.today - 3
        )

        result.success?.should == false
        result.errors.for(:subscription).on(:first_billing_date).first.code.should == Braintree::ErrorCodes::Subscription::FirstBillingDateCannotBeInThePast
      end
    end

    context "merchant_account_id" do
      it "defaults to the default merchant account if no merchant_account_id is provided" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id]
        )

        result.success?.should == true
        result.subscription.merchant_account_id.should == SpecHelper::DefaultMerchantAccountId
      end

      it "allows setting the merchant_account_id" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :merchant_account_id => SpecHelper::NonDefaultMerchantAccountId
        )

        result.success?.should == true
        result.subscription.merchant_account_id.should == SpecHelper::NonDefaultMerchantAccountId
      end
    end

    context "number_of_billing_cycles" do
      it "sets the number of billing cycles on the subscription when provided" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :number_of_billing_cycles => 10
        )

        result.success?.should == true
        result.subscription.number_of_billing_cycles.should == 10
      end

      it "sets the number of billing cycles to nil if :never_expires => true" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :never_expires => true
        )

        result.success?.should == true
        result.subscription.number_of_billing_cycles.should == nil
      end
    end

    context "trial period" do
      context "defaults to the plan's trial period settings" do
        it "with no trial" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => SpecHelper::TriallessPlan[:id]
          )

          result.subscription.trial_period.should == false
          result.subscription.trial_duration.should == nil
          result.subscription.trial_duration_unit.should == nil
        end

        it "with a trial" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => SpecHelper::TrialPlan[:id]
          )

          result.subscription.trial_period.should == true
          result.subscription.trial_duration.should == 2
          result.subscription.trial_duration_unit.should == Braintree::Subscription::TrialDurationUnit::Day
        end

        it "can alter the trial period params" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => SpecHelper::TrialPlan[:id],
            :trial_duration => 5,
            :trial_duration_unit => Braintree::Subscription::TrialDurationUnit::Month
          )

          result.subscription.trial_period.should == true
          result.subscription.trial_duration.should == 5
          result.subscription.trial_duration_unit.should == Braintree::Subscription::TrialDurationUnit::Month
        end

        it "can override the trial_period param" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => SpecHelper::TrialPlan[:id],
            :trial_period => false
          )

          result.subscription.trial_period.should == false
        end

        it "doesn't create a transaction if there's a trial period" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => SpecHelper::TrialPlan[:id]
          )

          result.subscription.transactions.size.should == 0
        end
      end

      context "no trial period" do
        it "creates a transaction if no trial period" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => SpecHelper::TriallessPlan[:id]
          )

          result.subscription.transactions.size.should == 1
          result.subscription.transactions.first.should be_a(Braintree::Transaction)
          result.subscription.transactions.first.amount.should == SpecHelper::TriallessPlan[:price]
          result.subscription.transactions.first.type.should == Braintree::Transaction::Type::Sale
          result.subscription.transactions.first.subscription_id.should == result.subscription.id
        end

        it "does not create the subscription and returns the transaction if the transaction is not successful" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => SpecHelper::TriallessPlan[:id],
            :price => Braintree::Test::TransactionAmounts::Decline
          )

          result.success?.should be_false
          result.transaction.status.should == Braintree::Transaction::Status::ProcessorDeclined
          result.message.should == "Do Not Honor"
        end
      end

      context "price" do
        it "defaults to the plan's price" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => SpecHelper::TrialPlan[:id]
          )

          result.subscription.price.should == SpecHelper::TrialPlan[:price]
        end

        it "can be overridden" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => SpecHelper::TrialPlan[:id],
            :price => 98.76
          )

          result.subscription.price.should == BigDecimal.new("98.76")
        end
      end
    end

    context "validation errors" do
      it "has validation errors on id" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :id => "invalid token"
        )
        result.success?.should == false
        result.errors.for(:subscription).on(:id)[0].message.should == "ID is invalid (use only letters, numbers, '-', and '_')."
      end

      it "has validation errors on duplicate id" do
        duplicate_token = "duplicate_token_#{rand(36**8).to_s(36)}"
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :id => duplicate_token
        )
        result.success?.should == true

        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :id => duplicate_token
        )
        result.success?.should == false
        result.errors.for(:subscription).on(:id)[0].message.should == "ID has already been taken."
      end

      it "trial duration required" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :trial_period => true,
          :trial_duration => nil
        )
        result.success?.should == false
        result.errors.for(:subscription).on(:trial_duration)[0].message.should == "Trial Duration is required."
      end

      it "trial duration unit required" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :trial_period => true,
          :trial_duration => 2,
          :trial_duration_unit => nil
        )
        result.success?.should == false
        result.errors.for(:subscription).on(:trial_duration_unit)[0].message.should == "Trial Duration Unit is invalid."
      end
    end

    context "add_ons and discounts" do
      it "does not inherit the add_ons and discounts from the plan when do_not_inherit_add_ons_or_discounts is set" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::AddOnDiscountPlan[:id],
          :options => {:do_not_inherit_add_ons_or_discounts => true}
        )
        result.success?.should == true

        subscription = result.subscription

        subscription.add_ons.size.should == 0
        subscription.discounts.size.should == 0
      end

      it "inherits the add_ons and discounts from the plan when not specified" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::AddOnDiscountPlan[:id]
        )
        result.success?.should == true

        subscription = result.subscription

        subscription.add_ons.size.should == 2
        add_ons = subscription.add_ons.sort_by { |add_on| add_on.id }

        add_ons.first.id.should == "increase_10"
        add_ons.first.amount.should == BigDecimal.new("10.00")
        add_ons.first.quantity.should == 1
        add_ons.first.number_of_billing_cycles.should be_nil
        add_ons.first.never_expires?.should be_true

        add_ons.last.id.should == "increase_20"
        add_ons.last.amount.should == BigDecimal.new("20.00")
        add_ons.last.quantity.should == 1
        add_ons.last.number_of_billing_cycles.should be_nil
        add_ons.last.never_expires?.should be_true

        subscription.discounts.size.should == 2
        discounts = subscription.discounts.sort_by { |discount| discount.id }

        discounts.first.id.should == "discount_11"
        discounts.first.amount.should == BigDecimal.new("11.00")
        discounts.first.quantity.should == 1
        discounts.first.number_of_billing_cycles.should be_nil
        discounts.first.never_expires?.should be_true

        discounts.last.id.should == "discount_7"
        discounts.last.amount.should == BigDecimal.new("7.00")
        discounts.last.quantity.should == 1
        discounts.last.number_of_billing_cycles.should be_nil
        discounts.last.never_expires?.should be_true
      end

      it "allows overriding of inherited add_ons and discounts" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::AddOnDiscountPlan[:id],
          :add_ons => {
            :update => [
              {
                :amount => BigDecimal.new("50.00"),
                :existing_id => SpecHelper::AddOnIncrease10,
                :quantity => 2,
                :number_of_billing_cycles => 5
              }
            ]
          },
          :discounts => {
            :update => [
              {
                :amount => BigDecimal.new("15.00"),
                :existing_id => SpecHelper::Discount7,
                :quantity => 3,
                :never_expires => true
              }
            ]
          }
        )
        result.success?.should == true

        subscription = result.subscription

        subscription.add_ons.size.should == 2
        add_ons = subscription.add_ons.sort_by { |add_on| add_on.id }

        add_ons.first.id.should == "increase_10"
        add_ons.first.amount.should == BigDecimal.new("50.00")
        add_ons.first.quantity.should == 2
        add_ons.first.number_of_billing_cycles.should == 5
        add_ons.first.never_expires?.should be_false

        add_ons.last.id.should == "increase_20"
        add_ons.last.amount.should == BigDecimal.new("20.00")
        add_ons.last.quantity.should == 1

        subscription.discounts.size.should == 2
        discounts = subscription.discounts.sort_by { |discount| discount.id }

        discounts.first.id.should == "discount_11"
        discounts.first.amount.should == BigDecimal.new("11.00")
        discounts.first.quantity.should == 1

        discounts.last.id.should == "discount_7"
        discounts.last.amount.should == BigDecimal.new("15.00")
        discounts.last.quantity.should == 3
        discounts.last.number_of_billing_cycles.should be_nil
        discounts.last.never_expires?.should be_true
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
          }
        )
        result.success?.should == true

        subscription = result.subscription

        subscription.add_ons.size.should == 1
        subscription.add_ons.first.id.should == "increase_20"
        subscription.add_ons.first.amount.should == BigDecimal.new("20.00")
        subscription.add_ons.first.quantity.should == 1

        subscription.discounts.size.should == 1
        subscription.discounts.last.id.should == "discount_11"
        subscription.discounts.last.amount.should == BigDecimal.new("11.00")
        subscription.discounts.last.quantity.should == 1
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
          }
        )
        result.success?.should == true
        subscription = result.subscription

        subscription.add_ons.size.should == 3
        add_ons = subscription.add_ons.sort_by { |add_on| add_on.id }

        add_ons[0].id.should == "increase_10"
        add_ons[0].amount.should == BigDecimal.new("10.00")
        add_ons[0].quantity.should == 1

        add_ons[1].id.should == "increase_20"
        add_ons[1].amount.should == BigDecimal.new("20.00")
        add_ons[1].quantity.should == 1

        add_ons[2].id.should == "increase_30"
        add_ons[2].amount.should == BigDecimal.new("30.00")
        add_ons[2].quantity.should == 1

        subscription.discounts.size.should == 3
        discounts = subscription.discounts.sort_by { |discount| discount.id }

        discounts[0].id.should == "discount_11"
        discounts[0].amount.should == BigDecimal.new("11.00")
        discounts[0].quantity.should == 1

        discounts[1].id.should == "discount_15"
        discounts[1].amount.should == BigDecimal.new("15.00")
        discounts[1].quantity.should == 1

        discounts[2].id.should == "discount_7"
        discounts[2].amount.should == BigDecimal.new("7.00")
        discounts[2].quantity.should == 1
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
          }
        )
        result.success?.should == false
        result.errors.for(:subscription).for(:add_ons).for(:update).for_index(0).on(:amount)[0].code.should == Braintree::ErrorCodes::Subscription::Modification::AmountIsInvalid
        result.errors.for(:subscription).for(:add_ons).for(:update).for_index(1).on(:quantity)[0].code.should == Braintree::ErrorCodes::Subscription::Modification::QuantityIsInvalid
      end
    end
  end

  describe "self.find" do
    it "finds a subscription" do
      result = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TrialPlan[:id]
      )
      result.success?.should == true

      Braintree::Subscription.find(result.subscription.id).should == result.subscription
    end

    it "raises Braintree::NotFoundError if it cannot find" do
      expect {
        Braintree::Subscription.find('noSuchSubscription')
      }.to raise_error(Braintree::NotFoundError, 'subscription with id "noSuchSubscription" not found')
    end
  end

  describe "self.update" do
    before(:each) do
      @subscription = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :price => 54.32,
        :plan_id => SpecHelper::TriallessPlan[:id]
      ).subscription
    end

    it "allows changing the merchant_account_id" do
      result = Braintree::Subscription.update(@subscription.id,
        :merchant_account_id => SpecHelper::NonDefaultMerchantAccountId
      )

      result.success?.should == true
      result.subscription.merchant_account_id.should == SpecHelper::NonDefaultMerchantAccountId
    end

    it "allows changing the payment_method_token" do
      new_credit_card = Braintree::CreditCard.create!(
        :customer_id => @credit_card.customer_id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2010"
      )

      result = Braintree::Subscription.update(@subscription.id,
        :payment_method_token => new_credit_card.token
      )

      result.subscription.payment_method_token.should == new_credit_card.token
    end

    context "when successful" do
      it "returns a success response with the updated subscription if valid" do
        new_id = rand(36**9).to_s(36)
        result = Braintree::Subscription.update(@subscription.id,
          :id => new_id,
          :price => 9999.88,
          :plan_id => SpecHelper::TrialPlan[:id]
        )

        result.success?.should == true
        result.subscription.id.should =~ /#{new_id}/
        result.subscription.plan_id.should == SpecHelper::TrialPlan[:id]
        result.subscription.price.should == BigDecimal.new("9999.88")
      end

      it "prorates if there is a charge (because merchant has proration option enabled in control panel)" do
        result = Braintree::Subscription.update(@subscription.id,
          :price => @subscription.price.to_f + 1
        )

        result.success?.should == true
        result.subscription.price.to_f.should == @subscription.price.to_f + 1
        result.subscription.transactions.size.should == @subscription.transactions.size + 1
      end

      it "allows the user to force proration if there is a charge" do
        result = Braintree::Subscription.update(@subscription.id,
          :price => @subscription.price.to_f + 1,
          :options => { :prorate_charges => true }
        )

        result.success?.should == true
        result.subscription.price.to_f.should == @subscription.price.to_f + 1
        result.subscription.transactions.size.should == @subscription.transactions.size + 1
      end

      it "allows the user to prevent proration if there is a charge" do
        result = Braintree::Subscription.update(@subscription.id,
          :price => @subscription.price.to_f + 1,
          :options => { :prorate_charges => false }
        )

        result.success?.should == true
        result.subscription.price.to_f.should == @subscription.price.to_f + 1
        result.subscription.transactions.size.should == @subscription.transactions.size
      end

      it "doesn't prorate if price decreases" do
        result = Braintree::Subscription.update(@subscription.id,
          :price => @subscription.price.to_f - 1
        )

        result.success?.should == true
        result.subscription.price.to_f.should == @subscription.price.to_f - 1
        result.subscription.transactions.size.should == @subscription.transactions.size
      end
    end

    context "when unsuccessful" do
      before(:each) do
        @subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id]
        ).subscription
      end

      it "raises NotFoundError if the subscription can't be found" do
        expect {
          Braintree::Subscription.update(rand(36**9).to_s(36),
            :price => 58.20
          )
        }.to raise_error(Braintree::NotFoundError)
      end

      it "has validation errors on id" do
        result = Braintree::Subscription.update(@subscription.id, :id => "invalid token")
        result.success?.should == false
        result.errors.for(:subscription).on(:id)[0].code.should == Braintree::ErrorCodes::Subscription::TokenFormatIsInvalid
      end

      it "has a price" do
        result = Braintree::Subscription.update(@subscription.id, :price => "")
        result.success?.should == false
        result.errors.for(:subscription).on(:price)[0].code.should == Braintree::ErrorCodes::Subscription::PriceCannotBeBlank
      end

      it "has a properly formatted price" do
        result = Braintree::Subscription.update(@subscription.id, :price => "9.2.1 apples")
        result.success?.should == false
        result.errors.for(:subscription).on(:price)[0].code.should == Braintree::ErrorCodes::Subscription::PriceFormatIsInvalid
      end

      it "has validation errors on duplicate id" do
        duplicate_id = "new_id_#{rand(36**6).to_s(36)}"
        duplicate = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :id => duplicate_id
        )
        result = Braintree::Subscription.update(
          @subscription.id,
          :id => duplicate_id
        )
        result.success?.should == false
        result.errors.for(:subscription).on(:id)[0].code.should == Braintree::ErrorCodes::Subscription::IdIsInUse
      end

      it "cannot update a canceled subscription" do
        subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :price => 54.32,
          :plan_id => SpecHelper::TriallessPlan[:id]
        ).subscription

        result = Braintree::Subscription.cancel(subscription.id)
        result.success?.should == true

        result = Braintree::Subscription.update(subscription.id,
          :price => 123.45
        )
        result.success?.should == false
        result.errors.for(:subscription)[0].code.should == Braintree::ErrorCodes::Subscription::CannotEditCanceledSubscription
      end
    end

    context "number_of_billing_cycles" do
      it "sets the number of billing cycles on the subscription when provided" do
        subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :number_of_billing_cycles => 10
        ).subscription

        result = Braintree::Subscription.update(
          subscription.id,
          :number_of_billing_cycles => 5
        )

        result.subscription.number_of_billing_cycles.should == 5
      end

      it "sets the number of billing cycles to nil if :never_expires => true" do
        subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :number_of_billing_cycles => 10
        ).subscription

        result = Braintree::Subscription.update(
          subscription.id,
          :never_expires => true
        )

        result.success?.should == true
        result.subscription.number_of_billing_cycles.should == nil
        result.subscription.never_expires?.should be_true
      end
    end

    context "add_ons and discounts" do
      it "can update add_ons and discounts" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::AddOnDiscountPlan[:id]
        )
        result.success?.should == true
        subscription = result.subscription

        result = Braintree::Subscription.update(
          subscription.id,
          :add_ons => {
            :update => [
              {
                :existing_id => subscription.add_ons.first.id,
                :amount => BigDecimal.new("99.99"),
                :quantity => 12
              }
            ]
          },
          :discounts => {
            :update => [
              {
                :existing_id => subscription.discounts.first.id,
                :amount => BigDecimal.new("88.88"),
                :quantity => 9
              }
            ]
          }
        )

        subscription = result.subscription

        subscription.add_ons.size.should == 2
        add_ons = subscription.add_ons.sort_by { |add_on| add_on.id }

        add_ons.first.amount.should == BigDecimal.new("99.99")
        add_ons.first.quantity.should == 12

        subscription.discounts.size.should == 2
        discounts = subscription.discounts.sort_by { |discount| discount.id }

        discounts.last.amount.should == BigDecimal.new("88.88")
        discounts.last.quantity.should == 9
      end

      it "allows adding new add_ons and discounts" do
        subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::AddOnDiscountPlan[:id]
        ).subscription

        result = Braintree::Subscription.update(subscription.id,
          :add_ons => {
            :add => [{:inherited_from_id => SpecHelper::AddOnIncrease30}]
          },
          :discounts => {
            :add => [{:inherited_from_id => SpecHelper::Discount15}]
          }
        )

        result.success?.should == true
        subscription = result.subscription

        subscription.add_ons.size.should == 3
        add_ons = subscription.add_ons.sort_by { |add_on| add_on.id }

        add_ons[0].id.should == "increase_10"
        add_ons[0].amount.should == BigDecimal.new("10.00")
        add_ons[0].quantity.should == 1

        add_ons[1].id.should == "increase_20"
        add_ons[1].amount.should == BigDecimal.new("20.00")
        add_ons[1].quantity.should == 1

        add_ons[2].id.should == "increase_30"
        add_ons[2].amount.should == BigDecimal.new("30.00")
        add_ons[2].quantity.should == 1

        subscription.discounts.size.should == 3
        discounts = subscription.discounts.sort_by { |discount| discount.id }

        discounts[0].id.should == "discount_11"
        discounts[0].amount.should == BigDecimal.new("11.00")
        discounts[0].quantity.should == 1

        discounts[1].id.should == "discount_15"
        discounts[1].amount.should == BigDecimal.new("15.00")
        discounts[1].quantity.should == 1

        discounts[2].id.should == "discount_7"
        discounts[2].amount.should == BigDecimal.new("7.00")
        discounts[2].quantity.should == 1
      end

      it "allows replacing entire set of add_ons and discounts" do
        subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::AddOnDiscountPlan[:id]
        ).subscription

        result = Braintree::Subscription.update(subscription.id,
          :add_ons => {
            :add => [{:inherited_from_id => SpecHelper::AddOnIncrease30}]
          },
          :discounts => {
            :add => [{:inherited_from_id => SpecHelper::Discount15}]
          },
          :options => {:replace_all_add_ons_and_discounts => true}
        )

        result.success?.should == true
        subscription = result.subscription

        subscription.add_ons.size.should == 1

        subscription.add_ons[0].amount.should == BigDecimal.new("30.00")
        subscription.add_ons[0].quantity.should == 1

        subscription.discounts.size.should == 1

        subscription.discounts[0].amount.should == BigDecimal.new("15.00")
        subscription.discounts[0].quantity.should == 1
      end

      it "allows deleting of add_ons and discounts" do
        subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::AddOnDiscountPlan[:id]
        ).subscription

        result = Braintree::Subscription.update(subscription.id,
          :add_ons => {
            :remove => [SpecHelper::AddOnIncrease10]
          },
          :discounts => {
            :remove => [SpecHelper::Discount7]
          }
        )
        result.success?.should == true

        subscription = result.subscription

        subscription.add_ons.size.should == 1
        subscription.add_ons.first.amount.should == BigDecimal.new("20.00")
        subscription.add_ons.first.quantity.should == 1

        subscription.discounts.size.should == 1
        subscription.discounts.last.amount.should == BigDecimal.new("11.00")
        subscription.discounts.last.quantity.should == 1
      end
    end
  end

  describe "self.cancel" do
    it "returns a success response with the updated subscription if valid" do
      subscription = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :price => 54.32,
        :plan_id => SpecHelper::TriallessPlan[:id]
      ).subscription

      result = Braintree::Subscription.cancel(subscription.id)
      result.success?.should == true
      result.subscription.status.should == Braintree::Subscription::Status::Canceled
    end

    it "returns a validation error if record not found" do
      expect {
        r = Braintree::Subscription.cancel('noSuchSubscription')
      }.to raise_error(Braintree::NotFoundError, 'subscription with id "noSuchSubscription" not found')
    end

    it "cannot be canceled if already canceled" do
      subscription = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :price => 54.32,
        :plan_id => SpecHelper::TriallessPlan[:id]
      ).subscription

      result = Braintree::Subscription.cancel(subscription.id)
      result.success?.should == true
      result.subscription.status.should == Braintree::Subscription::Status::Canceled

      result = Braintree::Subscription.cancel(subscription.id)
      result.success?.should == false
      result.errors.for(:subscription)[0].code.should == "81905"
    end
  end

  describe "self.search" do
    describe "id" do
      it "works using the is operator" do
        id = rand(36**8).to_s(36)
        subscription1 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :id => "subscription1_#{id}"
        ).subscription

        subscription2 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :id => "subscription2_#{id}"
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.id.is "subscription1_#{id}"
        end

        collection.should include(subscription1)
        collection.should_not include(subscription2)
      end
    end

    describe "merchant_account_id" do
      it "is searchable using the is or in operator" do
        subscription1 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :merchant_account_id => SpecHelper::DefaultMerchantAccountId,
          :price => "1"
        ).subscription

        subscription2 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :merchant_account_id => SpecHelper::NonDefaultMerchantAccountId,
          :price => "1"
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.merchant_account_id.is SpecHelper::DefaultMerchantAccountId
          search.price.is "1"
        end

        collection.should include(subscription1)
        collection.should_not include(subscription2)

        collection = Braintree::Subscription.search do |search|
          search.merchant_account_id.in [SpecHelper::DefaultMerchantAccountId, SpecHelper::NonDefaultMerchantAccountId]
          search.price.is "1"
        end

        collection.should include(subscription1)
        collection.should include(subscription2)
      end
    end

    describe "plan_id" do
      it "works using the is operator" do
        trialless_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :price => "2"
        ).subscription

        trial_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :price => "2"
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.plan_id.is SpecHelper::TriallessPlan[:id]
          search.price.is "2"
        end

        collection.should include(trialless_subscription)
        collection.should_not include(trial_subscription)
      end
    end

    describe "price" do
      it "works using the is operator" do
        subscription_500 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :price => "5.00"
        ).subscription

        subscription_501 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :price => "5.01"
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.price.is "5.00"
        end

        collection.should include(subscription_500)
        collection.should_not include(subscription_501)
      end
    end

    describe "days_past_due" do
      it "is backwards-compatible for 'is'" do
        active_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :price => "6"
        ).subscription

        past_due_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :price => "6"
        ).subscription

        SpecHelper.make_past_due(past_due_subscription, 5)

        collection = Braintree::Subscription.search do |search|
          search.price.is "6.00"
          search.days_past_due.is 5
        end

        collection.should include(past_due_subscription)
        collection.should_not include(active_subscription)
        collection.each do |s|
          s.status.should == Braintree::Subscription::Status::PastDue
        end
      end

      it "passes a smoke test" do
        subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id]
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.days_past_due.between 1, 20
        end

        collection.should_not include(subscription)
        collection.each do |s|
          s.days_past_due.should >= 1
          s.days_past_due.should <= 20
        end
      end
    end

    describe "billing_cycles_remaining" do
      it "passes a smoke test" do
        subscription_5 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id],
          :number_of_billing_cycles => 5
        ).subscription

        subscription_9 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :number_of_billing_cycles => 10
        ).subscription

        subscription_15 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id],
          :number_of_billing_cycles => 15
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.billing_cycles_remaining.between 5, 10
        end

        collection.should include(subscription_5)
        collection.should include(subscription_9)
        collection.should_not include(subscription_15)
      end
    end

    it "returns multiple results" do
      (110 - Braintree::Subscription.search.maximum_size).times do
        Braintree::Subscription.create(:payment_method_token => @credit_card.token, :plan_id => SpecHelper::TrialPlan[:id])
      end

      collection = Braintree::Subscription.search
      collection.maximum_size.should > 100

      subscriptions_ids = collection.map {|t| t.id }.uniq.compact
      subscriptions_ids.size.should == collection.maximum_size
    end
  end

  describe "self.retry_charge" do
    it "is successful with only subscription id" do
      subscription = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id]
      ).subscription
      SpecHelper.make_past_due(subscription)

      result = Braintree::Subscription.retry_charge(subscription.id)

      result.success?.should == true
      transaction = result.transaction

      transaction.amount.should == subscription.price
      transaction.processor_authorization_code.should_not be_nil
      transaction.type.should == Braintree::Transaction::Type::Sale
      transaction.status.should == Braintree::Transaction::Status::Authorized
    end

    it "is successful with subscription id and amount" do
      subscription = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id]
      ).subscription
      SpecHelper.make_past_due(subscription)

      result = Braintree::Subscription.retry_charge(subscription.id, Braintree::Test::TransactionAmounts::Authorize)

      result.success?.should == true
      transaction = result.transaction

      transaction.amount.should == BigDecimal.new(Braintree::Test::TransactionAmounts::Authorize)
      transaction.processor_authorization_code.should_not be_nil
      transaction.type.should == Braintree::Transaction::Type::Sale
      transaction.status.should == Braintree::Transaction::Status::Authorized
    end
  end
end
