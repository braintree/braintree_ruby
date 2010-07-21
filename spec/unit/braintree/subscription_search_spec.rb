require File.dirname(__FILE__) + "/../spec_helper"

module Braintree
  describe SubscriptionSearch do
    context "status" do
      it "allows Active, Canceled and PastDue" do
        search = SubscriptionSearch.new

        lambda do
          search.status.in(
            Subscription::Status::Active,
            Subscription::Status::Canceled,
            Subscription::Status::Expired,
            Subscription::Status::PastDue
          )
        end.should_not raise_error
      end
    end

    context "days_past_due" do
      it "correctly builds a hash with the criteria" do
        search = SubscriptionSearch.new
        search.days_past_due.is "30"

        search.to_hash.should == {:days_past_due => {:is => "30"}}
      end

      it "coverts ints to strings" do
        search = SubscriptionSearch.new
        search.days_past_due.is 30

        search.to_hash.should == {:days_past_due => {:is => "30"}}
      end
    end
  end
end
