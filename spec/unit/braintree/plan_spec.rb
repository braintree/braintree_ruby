require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Plan do
  describe "initialize" do
    it "has all fields" do
      expected = {
        :id => "test_id",
        :merchant_id => "test_merchant_id",
        :billing_day_of_month => "monday",
        :billing_frequency => "1",
        :currency_iso_code => "USD",
        :description => "some description",
        :discounts => [],
        :name => "test plan",
        :number_of_billing_cycles => "0",
        :price => "100",
        :trial_duration => "3",
        :trial_duration_unit => "day",
        :trial_period => "",
        :created_at => Time.now,
        :updated_at => Time.now,
        :add_ons => []
      }
      plan = Braintree::Plan._new(:gateway, expected)

      expected.each do |key,value|
        plan.send(key).should == value
      end
    end

    it "contains add_ons and discounts" do
      plan = Braintree::Plan._new(:gateway, {:add_ons => [{:name => "add on"}], :discounts => [{:name => "discount"}]})
      plan.add_ons.first.name.should == "add on"
      plan.discounts.first.name.should == "discount"
    end
  end
end
