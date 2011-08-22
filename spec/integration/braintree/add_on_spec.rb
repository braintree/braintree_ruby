require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::AddOn do
  describe "self.all" do
    it "gets all add_ons" do
      add_ons = Braintree::AddOn.all
      add_ons.size.should > 0
      add_ons.all? {|add_on| add_on.kind == "add_on" }.should == true
    end
  end
end
