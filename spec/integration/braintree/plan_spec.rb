require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::Plan do

  describe "self.all" do
    it "gets all plans" do
      plan_token = "test_plan_#{rand(36**8).to_s(36)}"
      attributes = {
        :id => plan_token,
        :billing_day_of_month => 1,
        :billing_frequency => 1,
        :currency_iso_code => "USD",
        :description => "some description",
        :name => "ruby_test plan",
        :number_of_billing_cycles => 1,
        :price => "1.00",
        :trial_period => false,
      }
      create_plan_for_tests(attributes)

      add_on_name = "ruby_add_on"
      discount_name = "ruby_discount"
      create_modification_for_tests(:kind => "add_on", :plan_id => plan_token, :amount => "1.00", :name => add_on_name)
      create_modification_for_tests(:kind => "discount", :plan_id => plan_token, :amount => "1.00", :name => discount_name)

      plans = Braintree::Plan.all
      plan = plans.select { |plan| plan.id == plan_token }.first
      expect(plan).not_to be_nil
      expect(plan.id).to eq(attributes[:id])
      expect(plan.billing_day_of_month).to eq(attributes[:billing_day_of_month])
      expect(plan.billing_frequency).to eq(attributes[:billing_frequency])
      expect(plan.currency_iso_code).to eq(attributes[:currency_iso_code])
      expect(plan.description).to eq(attributes[:description])
      expect(plan.name).to eq(attributes[:name])
      expect(plan.number_of_billing_cycles).to eq(attributes[:number_of_billing_cycles])
      expect(plan.price).to eq(Braintree::Util.to_big_decimal("1.00"))
      expect(plan.trial_period).to eq(attributes[:trial_period])
      expect(plan.created_at).not_to be_nil
      expect(plan.updated_at).not_to be_nil
      expect(plan.add_ons.first.name).to eq(add_on_name)
      expect(plan.discounts.first.name).to eq(discount_name)
    end

    it "returns an empty array if there are no plans" do
      gateway = Braintree::Gateway.new(SpecHelper::TestMerchantConfig)
      plans = gateway.plan.all
      expect(plans).to eq([])
    end
  end

  describe "self.create" do
    let(:attributes) do
      {
        :billing_day_of_month => 12,
        :billing_frequency => 1,
        :currency_iso_code => "USD",
        :description => "description on create",
        :name => "my new plan name",
        :number_of_billing_cycles => 1,
        :price => "9.99",
        :trial_period => false
      }

      it "is successful with given params" do
        result = Braintree::Plan.create(attributes)
        expect(result.success?).to be_truthy
        expect(result.plan.billing_day_of_month).to eq 12
        expect(result.plan.description).to eq "description on create"
        expect(result.plan.name).to eq "my new plan name"
        expect(result.plan.price).to eq "9.99"
        expect(result.plan.billing_frequency).to eq 1
      end
    end
  end

  describe "self.find" do
    it "finds a plan" do
      plan = Braintree::Plan.create(
        :billing_day_of_month => 12,
        :billing_frequency => 1,
        :currency_iso_code => "USD",
        :description => "description on create",
        :name => "my new plan name",
        :number_of_billing_cycles => 1,
        :price => "9.99",
        :trial_period => false,
      ).plan

      found_plan = Braintree::Plan.find(plan.id)
      expect(found_plan.name).to eq plan.name
    end

    it "raises Braintree::NotFoundError if it cannot find" do
      expect {
        Braintree::Plan.find("noSuchPlan")
      }.to raise_error(Braintree::NotFoundError, 'plan with id "noSuchPlan" not found')
    end
  end

  describe "self.update!" do
    before(:each) do
      @plan = Braintree::Plan.create(
        :billing_day_of_month => 12,
        :billing_frequency => 1,
        :currency_iso_code => "USD",
        :description => "description on create",
        :name => "my new plan name",
        :number_of_billing_cycles => 1,
        :price => "9.99",
        :trial_period => false,
      ).plan
    end

    it "returns the updated plan if valid" do
      plan = Braintree::Plan.update!(@plan.id,
                                     :name => "updated name",
                                     :price => 99.88,
                                    )

      expect(plan.name).to eq "updated name"
      expect(plan.price).to eq BigDecimal("99.88")
    end

    it "raises a ValidationsFailed if invalid" do
      expect do
        Braintree::Plan.update!(@plan.id, :number_of_billing_cycles => "number of billing cycles")
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  def create_plan_for_tests(attributes)
    config = Braintree::Configuration.gateway.config
    config.http.post("#{config.base_merchant_path}/plans/create_plan_for_tests", :plan => attributes)
  end
end
