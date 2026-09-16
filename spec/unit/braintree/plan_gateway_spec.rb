require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::PlanGateway do
  let(:gateway) do
    config = Braintree::Configuration.new(
      :merchant_id => "merchant_id",
      :public_key => "public_key",
      :private_key => "private_key",
    )
    Braintree::Gateway.new(config)
  end

  describe "path traversal" do
    it "find raises an exception if the id is a traversal segment" do
      plan_gateway = Braintree::PlanGateway.new(gateway)

      expect do
        plan_gateway.find("../plans/victim_id")
      end.to raise_error(ArgumentError, "id contains invalid characters")
    end

    it "update raises an exception if the plan_id is a traversal segment" do
      plan_gateway = Braintree::PlanGateway.new(gateway)

      expect do
        plan_gateway.update("../plans/victim_id", {})
      end.to raise_error(ArgumentError, "plan_id contains invalid characters")
    end
  end
end
