require File.dirname(__FILE__) + "/../spec_helper"

describe Braintree::ErrorResult do
  describe "initialize" do
    it "initializes params, errors, and summary" do
      errors = {
        :scope => {
          :errors => [{:code => "123", :message => "something is invalid", :attribute => "something"}]
        }
      }
      result = Braintree::ErrorResult.new(:params => "params", :errors => errors, :summary => "Summary of errors")
      result.success?.should == false
      result.params.should == "params"
      result.errors.size.should == 1
      result.errors.for(:scope)[0].message.should == "something is invalid"
      result.errors.for(:scope)[0].attribute.should == "something"
      result.errors.for(:scope)[0].code.should == "123"
      result.summary.should == "Summary of errors"
    end

    it "ignores data other than params, errors, and summary" do
      # so that we can add more data into the response in the future without breaking the client lib
      expect do
        result = Braintree::ErrorResult.new(:params => "params", :errors => {:errors => []}, :extra => "is ignored", :summary => "foo bar")
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

    it "includes the credit_card_verification if there is one" do
      result = Braintree::ErrorResult.new(
        :params => "params",
        :errors => {},
        :verification => {},
        :transaction => nil
      )
      result.inspect.should include("credit_card_verification: #<Braintree::CreditCardVerification status: ")
    end

    it "does not include the credit_card_verification if there isn't one" do
      result = Braintree::ErrorResult.new(
        :params => "params",
        :errors => {},
        :verification => nil,
        :transaction => nil
      )
      result.inspect.should_not include("credit_card_verification")
    end

    it "includes the transaction if there is one" do
      result = Braintree::ErrorResult.new(
        :params => "params",
        :errors => {},
        :verification => nil,
        :transaction => {}
      )
      result.inspect.should include("transaction: #<Braintree::Transaction id: ")
    end

    it "does not include the transaction if there isn't one" do
      result = Braintree::ErrorResult.new(
        :params => "params",
        :errors => {},
        :verification => nil,
        :transaction => nil
      )
      result.inspect.should_not include("transaction")
    end
  end
end
