require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Discount do
  describe "self.all" do
    it "gets all discounts" do
      name = "ruby_discount"
      discount = create_modification_for_tests({ :kind => "discount", :amount => "1000", :name => name })
      discounts = Braintree::Discount.all
      discounts.size.should > 0
      discounts.select { |discount| discount.name == name }
      discount.kind.should == "discount"
      discount.amount.should == BigDecimal.new("10")
    end
  end
end
