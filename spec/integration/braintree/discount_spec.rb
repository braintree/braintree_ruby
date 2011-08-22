require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Discount do
  describe "self.all" do
    it "gets all discounts" do
      discounts = Braintree::Discount.all
      discounts.size.should > 0
      discounts.all? {|discount| discount.kind == "discount" }.should == true
    end
  end
end
