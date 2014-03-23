require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Dispute do
  describe "initialize" do
    it "handles nil reply_by_date" do
      dispute = Braintree::Dispute._new(
        :amount => "500.00",
        :received_date => "2014-03-01",
        :reply_by_date => nil
      )

      dispute.reply_by_date.should == nil
    end
  end
end
