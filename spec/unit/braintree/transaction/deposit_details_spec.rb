require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::Transaction::DepositDetails do
  describe "valid?" do
    it "returns true if deposit details are initialized" do
      details = Braintree::Transaction::DepositDetails.new(
        :deposit_date => Date.new(2013, 4, 1)
      )
      details.valid?.should == true
    end
    it "returns true if deposit details are initialized" do
      details = Braintree::Transaction::DepositDetails.new(
        :deposit_date => nil
      )
      details.valid?.should == false
    end
  end
end
