require File.dirname(__FILE__) + "/../spec_helper"

describe Braintree::Subscription do
  TrialPlan = {
    :description => "Plan for integration tests -- with trial",
    :id => "integration_trial_plan",
    :price => BigDecimal.new("43.21"),
    :trial_period => true,
    :trial_duration => 2,
    :trial_duration_unit => Braintree::Subscription::TrialDurationUnit::Day
  }

  TriallessPlan = {
    :description => "Plan for integration tests -- without a trial",
    :id => "integration_trialless_plan",
    :price => BigDecimal.new("12.34"),
    :trial_period => false
  }

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
        :plan_id => TriallessPlan[:id]
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
      result.subscription.payment_method_token.should == @credit_card.token
    end

    it "can set the id" do
      new_id = rand(36**9).to_s(36)
      result = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => TriallessPlan[:id],
        :id => new_id
      )

      date_format = /^\d{4}\D\d{1,2}\D\d{1,2}$/
      result.success?.should == true
      result.subscription.id.should == new_id
    end

    context "merchant_account_id" do
      it "defaults to the default merchant account if no merchant_account_id is provided" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => TriallessPlan[:id]
        )

        result.success?.should == true
        result.subscription.merchant_account_id.should == SpecHelper::DefaultMerchantAccountId
      end

      it "allows setting the merchant_account_id" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => TriallessPlan[:id],
          :merchant_account_id => SpecHelper::NonDefaultMerchantAccountId
        )

        result.success?.should == true
        result.subscription.merchant_account_id.should == SpecHelper::NonDefaultMerchantAccountId
      end
    end

    context "trial period" do
      context "defaults to the plan's trial period settings" do
        it "with no trial" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TriallessPlan[:id]
          )

          result.subscription.trial_period.should == false
          result.subscription.trial_duration.should == nil
          result.subscription.trial_duration_unit.should == nil
        end

        it "with a trial" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TrialPlan[:id]
          )

          result.subscription.trial_period.should == true
          result.subscription.trial_duration.should == 2
          result.subscription.trial_duration_unit.should == Braintree::Subscription::TrialDurationUnit::Day
        end

        it "can alter the trial period params" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TrialPlan[:id],
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
            :plan_id => TrialPlan[:id],
            :trial_period => false
          )

          result.subscription.trial_period.should == false
        end

        it "creates a transaction if no trial period" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TriallessPlan[:id]
          )

          result.subscription.transactions.size.should == 1
          result.subscription.transactions.first.should be_a(Braintree::Transaction)
          result.subscription.transactions.first.amount.should == TriallessPlan[:price]
          result.subscription.transactions.first.type.should == Braintree::Transaction::Type::Sale
          result.subscription.transactions.first.subscription_id.should == result.subscription.id
        end

        it "doesn't create a transaction if there's a trial period" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TrialPlan[:id]
          )

          result.subscription.transactions.size.should == 0
        end
      end

      context "price" do
        it "defaults to the plan's price" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TrialPlan[:id]
          )

          result.subscription.price.should == TrialPlan[:price]
        end

        it "can be overridden" do
          result = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TrialPlan[:id],
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
          :plan_id => TrialPlan[:id],
          :id => "invalid token"
        )
        result.success?.should == false
        result.errors.for(:subscription).on(:id)[0].message.should == "ID is invalid (use only letters, numbers, '-', and '_')."
      end

      it "has validation errors on duplicate id" do
        duplicate_token = "duplicate_token_#{rand(36**8).to_s(36)}"
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => TrialPlan[:id],
          :id => duplicate_token
        )
        result.success?.should == true

        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => TrialPlan[:id],
          :id => duplicate_token
        )
        result.success?.should == false
        result.errors.for(:subscription).on(:id)[0].message.should == "ID has already been taken."
      end

      it "trial duration required" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => TrialPlan[:id],
          :trial_period => true,
          :trial_duration => nil
        )
        result.success?.should == false
        result.errors.for(:subscription).on(:trial_duration)[0].message.should == "Trial Duration is required."
      end

      it "trial duration unit required" do
        result = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => TrialPlan[:id],
          :trial_period => true,
          :trial_duration => 2,
          :trial_duration_unit => nil
        )
        result.success?.should == false
        result.errors.for(:subscription).on(:trial_duration_unit)[0].message.should == "Trial Duration Unit is invalid."
      end

    end
  end

  describe "self.find" do
    it "finds a subscription" do
      result = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => TriallessPlan[:id]
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
        :plan_id => TriallessPlan[:id]
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
          :plan_id => TrialPlan[:id]
        )

        result.success?.should == true
        result.subscription.id.should =~ /#{new_id}/
        result.subscription.plan_id.should == TrialPlan[:id]
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
          :plan_id => TrialPlan[:id]
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
          :plan_id => TrialPlan[:id],
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
          :plan_id => TriallessPlan[:id]
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
  end


  describe "self.cancel" do
    it "returns a success response with the updated subscription if valid" do
      subscription = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :price => 54.32,
        :plan_id => TriallessPlan[:id]
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
        :plan_id => TriallessPlan[:id]
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
    context "search_fields" do
      it "correctly returns a result with no matches" do
        collection = Braintree::Subscription.search do |search|
          search.plan_id.is "not_a_real_plan_id"
        end

        collection.maximum_size.should == 0
      end

      context "is statement" do
        it "returns resource collection with matching results" do
          trialless_subscription = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TriallessPlan[:id]
          ).subscription

          trial_subscription = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TrialPlan[:id]
          ).subscription

          collection = Braintree::Subscription.search do |search|
            search.plan_id.is TriallessPlan[:id]
          end

          collection.should include(trialless_subscription)
          collection.should_not include(trial_subscription)
        end
      end

      context "is_not statement" do
        it "returns resource collection without matching results" do
          trialless_subscription = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TriallessPlan[:id]
          ).subscription

          trial_subscription = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TrialPlan[:id]
          ).subscription

          collection = Braintree::Subscription.search do |search|
            search.plan_id.is_not TriallessPlan[:id]
          end

          collection.should_not include(trialless_subscription)
          collection.should include(trial_subscription)
        end
      end

      context "ends_with statement" do
        it "returns resource collection with matching results" do
          trialless_subscription = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TriallessPlan[:id]
          ).subscription

          trial_subscription = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TrialPlan[:id]
          ).subscription

          collection = Braintree::Subscription.search do |search|
            search.plan_id.ends_with "trial_plan"
          end

          collection.should include(trial_subscription)
          collection.should_not include(trialless_subscription)
        end
      end

      context "starts_with statement" do
        it "returns resource collection with matching results" do
          trialless_subscription = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TriallessPlan[:id]
          ).subscription

          trial_subscription = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TrialPlan[:id]
          ).subscription

          collection = Braintree::Subscription.search do |search|
            search.plan_id.starts_with "integration_trial_p"
          end

          collection.should include(trial_subscription)
          collection.should_not include(trialless_subscription)
        end
      end

      context "contains statement" do
        it "returns resource collection with matching results" do
          trialless_subscription = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TriallessPlan[:id]
          ).subscription

          trial_subscription = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TrialPlan[:id]
          ).subscription

          collection = Braintree::Subscription.search do |search|
            search.plan_id.contains "trial_p"
          end

          collection.should include(trial_subscription)
          collection.should_not include(trialless_subscription)
        end
      end
    end

    context "multiple_value_fields" do
      context "in" do
        it "matches all values if none are specified" do
          subscription1 = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TriallessPlan[:id]
          ).subscription

          subscription2 = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TriallessPlan[:id]
          ).subscription

          Braintree::Subscription.cancel(subscription2.id)

          collection = Braintree::Subscription.search do |search|
            search.plan_id.is TriallessPlan[:id]
          end

          collection.should include(subscription1)
          collection.should include(subscription2)
        end

        it "returns only matching results" do
          subscription1 = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TriallessPlan[:id]
          ).subscription

          subscription2 = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TriallessPlan[:id]
          ).subscription

          Braintree::Subscription.cancel(subscription2.id)

          collection = Braintree::Subscription.search do |search|
            search.status.in Braintree::Subscription::Status::Active
          end

          collection.should include(subscription1)
          collection.should_not include(subscription2)
        end

        it "returns only matching results given an argument list" do
          subscription1 = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TriallessPlan[:id]
          ).subscription

          subscription2 = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TriallessPlan[:id]
          ).subscription

          Braintree::Subscription.cancel(subscription2.id)

          collection = Braintree::Subscription.search do |search|
            search.status.in Braintree::Subscription::Status::Active, Braintree::Subscription::Status::Canceled
          end

          collection.should include(subscription1)
          collection.should include(subscription2)
        end

        it "returns only matching results given an array" do
          subscription1 = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TriallessPlan[:id]
          ).subscription

          subscription2 = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => TriallessPlan[:id]
          ).subscription

          Braintree::Subscription.cancel(subscription2.id)

          collection = Braintree::Subscription.search do |search|
            search.status.in [Braintree::Subscription::Status::Active, Braintree::Subscription::Status::Canceled]
          end

          collection.should include(subscription1)
          collection.should include(subscription2)
        end
      end
    end

    it "returns multiple results" do
      (110 - Braintree::Subscription.search.maximum_size).times do
        Braintree::Subscription.create(:payment_method_token => @credit_card.token, :plan_id => TriallessPlan[:id])
      end

      collection = Braintree::Subscription.search
      collection.maximum_size.should > 100

      subscriptions_ids = collection.map {|t| t.id }.uniq.compact
      subscriptions_ids.size.should == collection.maximum_size
    end

  end

  describe "self.retry_charge" do
    it "is successful with only subscription id" do
      subscription = Braintree::Subscription.search do |search|
        search.status.in Braintree::Subscription::Status::PastDue
      end.first

      result = Braintree::Subscription.retry_charge(subscription.id)

      result.success?.should == true
      transaction = result.transaction

      transaction.amount.should == subscription.price
      transaction.processor_authorization_code.should_not be_nil
      transaction.type.should == Braintree::Transaction::Type::Sale
      transaction.status.should == Braintree::Transaction::Status::Authorized
    end

    it "is successful with subscription id and amount" do
      subscription = Braintree::Subscription.search do |search|
        search.status.in Braintree::Subscription::Status::PastDue
      end.first

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
