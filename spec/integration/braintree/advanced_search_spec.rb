require File.dirname(__FILE__) + "/../spec_helper"

describe Braintree::AdvancedSearch do
  before(:each) do
    @credit_card = Braintree::Customer.create!(
      :credit_card => {
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2010"
      }
    ).credit_cards[0]
  end

  context "text_fields" do
    it "is" do
      id = rand(36**8).to_s(36)
      subscription1 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :id => "subscription1_#{id}"
      ).subscription

      subscription2 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :id => "subscription2_#{id}"
      ).subscription

      collection = Braintree::Subscription.search do |search|
        search.id.is "subscription1_#{id}"
      end

      collection.should include(subscription1)
      collection.should_not include(subscription2)
    end

    it "is_not" do
      id = rand(36**8).to_s(36)
      subscription1 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :id => "subscription1_#{id}"
      ).subscription

      subscription2 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :id => "subscription2_#{id}"
      ).subscription

      collection = Braintree::Subscription.search do |search|
        search.id.is_not "subscription1_#{id}"
      end

      collection.should_not include(subscription1)
      collection.should include(subscription2)
    end

    it "starts_with" do
      id = rand(36**8).to_s(36)
      subscription1 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :id => "subscription1_#{id}"
      ).subscription

      subscription2 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :id => "subscription2_#{id}"
      ).subscription

      collection = Braintree::Subscription.search do |search|
        search.id.starts_with "subscription1_"
      end

      collection.should include(subscription1)
      collection.should_not include(subscription2)
    end

    it "ends_with" do
      id = rand(36**8).to_s(36)
      subscription1 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :id => "subscription1_#{id}"
      ).subscription

      subscription2 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :id => "subscription2_#{id}"
      ).subscription

      collection = Braintree::Subscription.search do |search|
        search.id.ends_with "1_#{id}"
      end

      collection.should include(subscription1)
      collection.should_not include(subscription2)
    end

    it "contains" do
      id = rand(36**8).to_s(36)
      subscription1 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :id => "subscription1_#{id}"
      ).subscription

      subscription2 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :id => "subscription2_#{id}"
      ).subscription

      collection = Braintree::Subscription.search do |search|
        search.id.contains "scription1_"
      end

      collection.should include(subscription1)
      collection.should_not include(subscription2)
    end
  end

  context "multiple_value_field" do
    context "in" do
      it "matches all values if none are specified" do
        subscription1 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id]
        ).subscription

        subscription2 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id]
        ).subscription

        Braintree::Subscription.cancel(subscription2.id)

        collection = Braintree::Subscription.search do |search|
          search.plan_id.is SpecHelper::TriallessPlan[:id]
        end

        collection.should include(subscription1)
        collection.should include(subscription2)
      end

      it "returns only matching results" do
        subscription1 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id]
        ).subscription

        subscription2 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id]
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
          :plan_id => SpecHelper::TriallessPlan[:id]
        ).subscription

        subscription2 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id]
        ).subscription

        Braintree::Subscription.cancel(subscription2.id)

        collection = Braintree::Subscription.search do |search|
          search.status.in Braintree::Subscription::Status::Active, Braintree::Subscription::Status::Canceled
        end

        collection.should include(subscription1)
        collection.should include(subscription2)
      end

      describe "is" do
        it "accepts single argument" do
          subscription1 = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => SpecHelper::TriallessPlan[:id]
          ).subscription

          subscription2 = Braintree::Subscription.create(
            :payment_method_token => @credit_card.token,
            :plan_id => SpecHelper::TriallessPlan[:id]
          ).subscription

          Braintree::Subscription.cancel(subscription2.id)

          collection = Braintree::Subscription.search do |search|
            search.status.is Braintree::Subscription::Status::Active
          end

          collection.should include(subscription1)
          collection.should_not include(subscription2)
        end
      end

      it "returns only matching results given an array" do
        subscription1 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id]
        ).subscription

        subscription2 = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id]
        ).subscription

        Braintree::Subscription.cancel(subscription2.id)

        collection = Braintree::Subscription.search do |search|
          search.status.in [Braintree::Subscription::Status::Active, Braintree::Subscription::Status::Canceled]
        end

        collection.should include(subscription1)
        collection.should include(subscription2)
      end

      it "returns expired subscriptions" do
        collection = Braintree::Subscription.search do |search|
          search.status.in [Braintree::Subscription::Status::Expired]
        end

        collection.maximum_size.should > 0
        collection.all? { |subscription| subscription.status.should == Braintree::Subscription::Status::Expired }
      end
    end
  end

  context "multiple_value_or_text_field" do
    describe "in" do
      it "works for the in operator" do
        plan_ids = [SpecHelper::TriallessPlan[:id], SpecHelper::TrialPlan[:id]]
        collection = Braintree::Subscription.search do |search|
          search.plan_id.in plan_ids
        end

        collection.maximum_size.should > 0
        collection.all? { |subscription| plan_ids.include?(subscription.plan_id) }
      end
    end

    context "a search with no matches" do
      it "works" do
        collection = Braintree::Subscription.search do |search|
          search.plan_id.is "not_a_real_plan_id"
        end

        collection.maximum_size.should == 0
      end
    end

    describe "is" do
      it "returns resource collection with matching results" do
        trialless_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id]
        ).subscription

        trial_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id]
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.plan_id.is SpecHelper::TriallessPlan[:id]
        end

        collection.should include(trialless_subscription)
        collection.should_not include(trial_subscription)
      end
    end

    describe "is_not" do
      it "returns resource collection without matching results" do
        trialless_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id]
        ).subscription

        trial_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id]
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.plan_id.is_not SpecHelper::TriallessPlan[:id]
        end

        collection.should_not include(trialless_subscription)
        collection.should include(trial_subscription)
      end
    end

    describe "ends_with" do
      it "returns resource collection with matching results" do
        trialless_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id]
        ).subscription

        trial_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id]
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.plan_id.ends_with "trial_plan"
        end

        collection.should include(trial_subscription)
        collection.should_not include(trialless_subscription)
      end
    end

    describe "starts_with" do
      it "returns resource collection with matching results" do
        trialless_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id]
        ).subscription

        trial_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id]
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.plan_id.starts_with "integration_trial_p"
        end

        collection.should include(trial_subscription)
        collection.should_not include(trialless_subscription)
      end
    end

    describe "contains" do
      it "returns resource collection with matching results" do
        trialless_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TriallessPlan[:id]
        ).subscription

        trial_subscription = Braintree::Subscription.create(
          :payment_method_token => @credit_card.token,
          :plan_id => SpecHelper::TrialPlan[:id]
        ).subscription

        collection = Braintree::Subscription.search do |search|
          search.plan_id.contains "trial_p"
        end

        collection.should include(trial_subscription)
        collection.should_not include(trialless_subscription)
      end
    end
  end

  context "range_field" do
    it "is" do
      subscription_500 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
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

    it "<=" do
      subscription_499 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TrialPlan[:id],
        :price => "4.99"
      ).subscription

      subscription_500 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :price => "5.00"
      ).subscription

      subscription_501 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TrialPlan[:id],
        :price => "5.01"
      ).subscription

      collection = Braintree::Subscription.search do |search|
        search.price <= "5.00"
      end

      collection.should include(subscription_499)
      collection.should include(subscription_500)
      collection.should_not include(subscription_501)
    end

    it ">=" do
      subscription_499 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TrialPlan[:id],
        :price => "4.99"
      ).subscription

      subscription_500 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :price => "5.00"
      ).subscription

      subscription_501 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TrialPlan[:id],
        :price => "5.01"
      ).subscription

      collection = Braintree::Subscription.search do |search|
        search.price >= "5.00"
      end

      collection.should_not include(subscription_499)
      collection.should include(subscription_500)
      collection.should include(subscription_501)
    end

    it "between" do
      subscription_499 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TrialPlan[:id],
        :price => "4.99"
      ).subscription

      subscription_500 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TriallessPlan[:id],
        :price => "5.00"
      ).subscription

      subscription_502 = Braintree::Subscription.create(
        :payment_method_token => @credit_card.token,
        :plan_id => SpecHelper::TrialPlan[:id],
        :price => "5.02"
      ).subscription

      collection = Braintree::Subscription.search do |search|
        search.price.between "4.99", "5.01"
      end

      collection.should include(subscription_499)
      collection.should include(subscription_500)
      collection.should_not include(subscription_502)
    end
  end
end
