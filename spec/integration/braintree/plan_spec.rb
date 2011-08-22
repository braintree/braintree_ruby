require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Plan do
  describe "self.all" do
    it "gets all plans" do
      plans = Braintree::Plan.all
      plans.size.should > 0
      plans.all? { |plan| plan.should be_kind_of(Braintree::Plan) }
    end

    it "has add_ons and discounts" do
      plans = Braintree::Plan.all
      plan = plans.find {|p| p.description == "Plan for integration tests -- with add-ons and discounts" }

      plan.should_not == nil
      plan.add_ons.first.kind.should == "add_on"
      plan.discounts.first.kind.should == "discount"
    end
  end
end
