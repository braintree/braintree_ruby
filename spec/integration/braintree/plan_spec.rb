require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Plan do

  describe "self.all" do
    it "gets all plans" do
      plan_token = "ruby_test_plan_#{rand(36**8).to_s(36)}"
      add_on_name = "ruby_add_on"
      discount_name = "ruby_discount"
      create_plan_for_tests(plan_token)
      create_modification_for_tests({ :kind => "add_on", :plan_id => plan_token, :amount => "1.00", :name => add_on_name })
      create_modification_for_tests({ :kind => "discount", :plan_id => plan_token, :amount => "1.00", :name => discount_name })

      plans = Braintree::Plan.all
      plan = plans.select { |plan| plan.id == plan_token }.first
      plan.should_not be_nil
      plan.add_ons.first.name.should == add_on_name
      plan.discounts.first.name.should == discount_name
    end
  end

  def create_plan_for_tests(token)
    plan_attributes = {
      :plan => {
        :currency_iso_code => "USD",
        :billing_frequency => 1,
        :name => "ruby_plan",
        :description => "testing",
        :price => "1.00",
        :id => token
      }
    }
    Braintree::Configuration.gateway.config.http.post "/plans/create_plan_for_tests", plan_attributes
  end
end
