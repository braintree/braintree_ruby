require File.dirname(__FILE__) + "/../spec_helper"

describe Braintree::ErrorResult do
  describe "initialize" do
    it "initializes params and errors" do
      errors = {
        :scope => {
          :errors => [{:code => "123", :message => "something is invalid", :attribute => "something"}]
        }
      }
      result = Braintree::ErrorResult.new(:params => "params", :errors => errors)
      result.success?.should == false
      result.params.should == "params"
      result.errors.size.should == 1
      result.errors.for(:scope)[0].message.should == "something is invalid"
      result.errors.for(:scope)[0].attribute.should == "something"
      result.errors.for(:scope)[0].code.should == "123"
    end

    it "ignores data other than params and errors" do
      # so that we can add more data into the response in the future without breaking the client lib
      expect do
        result = Braintree::ErrorResult.new(:params => "params", :errors => {:errors => []}, :extra => "is ignored")
      end.to_not raise_error
    end
  end

  describe "inspect" do
    it "shows errors 2 levels deep" do
      errors = {
        :level1 => {
          :errors => [{:code => "code1", :attribute => "attr", :message => "message"}],
          :level2 => {
            :errors => [{:code => "code2", :attribute => "attr2", :message => "message2"}],
          }
        }
      }
      result = Braintree::ErrorResult.new(:params => "params", :errors => errors)
      result.inspect.should == "#<Braintree::ErrorResult params:{...} errors:<level1:[(code1) message], level1/level2:[(code2) message2]>>"
    end
  end
end
