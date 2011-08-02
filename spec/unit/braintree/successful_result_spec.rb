require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::SuccessfulResult do
  describe "initialize" do
    it "creates attr readers the values in the hash" do
      result = Braintree::SuccessfulResult.new(
        :foo => "foo_value",
        :bar => "bar_value"
      )
      result.success?.should == true
      result.foo.should == "foo_value"
      result.bar.should == "bar_value"
    end

    it "can be initialized without any values" do
      result = Braintree::SuccessfulResult.new
      result.success?.should == true
    end
  end

  describe "inspect" do
    it "is pretty" do
      result = Braintree::SuccessfulResult.new(:foo => "foo_value")
      result.inspect.should == "#<Braintree::SuccessfulResult foo:\"foo_value\">"
    end
  end

  describe "payer_authentication_required?" do
    it "is always false" do
      Braintree::SuccessfulResult.new.payer_authentication_required?.should be_false
    end
  end
end
