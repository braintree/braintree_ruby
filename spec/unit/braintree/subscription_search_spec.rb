require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Braintree
  describe SubscriptionSearch do
    context "status" do
      it "allows Active, Canceled, Expired, and PastDue" do
        search = SubscriptionSearch.new

        expect do
          search.status.in(
            Subscription::Status::Active,
            Subscription::Status::Canceled,
            Subscription::Status::Expired,
            Subscription::Status::PastDue,
          )
        end.not_to raise_error
      end
    end

    context "in_trial_period" do
      it "allows true" do
        search = SubscriptionSearch.new
        search.in_trial_period.is true

        expect(search.to_hash).to eq({:in_trial_period => [true]})
      end

      it "allows false" do
        search = SubscriptionSearch.new
        search.in_trial_period.is false

        expect(search.to_hash).to eq({:in_trial_period => [false]})
      end
    end

    context "days_past_due" do
      it "correctly builds a hash with the criteria" do
        search = SubscriptionSearch.new
        search.days_past_due.is "30"

        expect(search.to_hash).to eq({:days_past_due => {:is => "30"}})
      end

      it "coverts ints to strings" do
        search = SubscriptionSearch.new
        search.days_past_due.is 30

        expect(search.to_hash).to eq({:days_past_due => {:is => "30"}})
      end
    end

    context "merchant_account_id" do
      it "builds a hash using the in operator" do
        search = SubscriptionSearch.new
        search.merchant_account_id.in "ma_id1", "ma_id2"

        expect(search.to_hash).to eq({:merchant_account_id => ["ma_id1", "ma_id2"]})
      end
    end

    context "plan_id" do
      it "starts_with" do
        search = SubscriptionSearch.new
        search.plan_id.starts_with "plan_"

        expect(search.to_hash).to eq({:plan_id => {:starts_with => "plan_"}})
      end

      it "ends_with" do
        search = SubscriptionSearch.new
        search.plan_id.ends_with "_id"

        expect(search.to_hash).to eq({:plan_id => {:ends_with => "_id"}})
      end

      it "is" do
        search = SubscriptionSearch.new
        search.plan_id.is "p_id"

        expect(search.to_hash).to eq({:plan_id => {:is => "p_id"}})
      end

      it "is_not" do
        search = SubscriptionSearch.new
        search.plan_id.is_not "p_id"

        expect(search.to_hash).to eq({:plan_id => {:is_not => "p_id"}})
      end

      it "contains" do
        search = SubscriptionSearch.new
        search.plan_id.contains "p_id"

        expect(search.to_hash).to eq({:plan_id => {:contains => "p_id"}})
      end

      it "in" do
        search = SubscriptionSearch.new
        search.plan_id.in ["plan1", "plan2"]

        expect(search.to_hash).to eq({:plan_id => ["plan1", "plan2"]})
      end
    end

    context "days_past_due" do
      it "is a range node" do
        search = SubscriptionSearch.new
        expect(search.days_past_due).to be_kind_of(Braintree::AdvancedSearch::RangeNode)
      end
    end

    context "billing_cycles_remaining" do
      it "is a range node" do
        search = SubscriptionSearch.new
        expect(search.billing_cycles_remaining).to be_kind_of(Braintree::AdvancedSearch::RangeNode)
      end
    end

    context "created_at" do
      it "is a range node" do
        search = SubscriptionSearch.new
        expect(search.created_at).to be_kind_of(Braintree::AdvancedSearch::RangeNode)
      end
    end

    context "id" do
      it "is" do
        search = SubscriptionSearch.new
        search.id.is "s_id"

        expect(search.to_hash).to eq({:id => {:is => "s_id"}})
      end
    end
  end
end
