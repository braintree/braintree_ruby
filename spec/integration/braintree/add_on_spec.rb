require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::AddOn do
  describe "self.all" do
    it "gets all add_ons" do
      name = "ruby_add_on"
      add_on = create_modification_for_tests({ :kind => "add_on", :amount => "1000", :name => name })
      add_ons = Braintree::AddOn.all
      add_ons.size.should > 0
      add_ons.select { |add_on| add_on.name == name }
      add_on.kind.should == "add_on"
      add_on.amount.should == BigDecimal.new("10")
    end
  end
end
