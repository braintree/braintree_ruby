require File.dirname(__FILE__) + "/../../spec_helper"

describe Braintree::Transaction::CreditCardDetails do
  describe "expiration_date" do
    it "concats expiration_month and expiration_year" do
      details = Braintree::Transaction::CreditCardDetails.new(
        :expiration_month => "08",
        :expiration_year => "2009"
      )
      details.expiration_date.should == "08/2009"
    end
  end

  describe "masked_number" do
    it "concatenates the bin, some *'s, and the last_4" do
      details = Braintree::Transaction::CreditCardDetails.new(
        :bin => "510510", :last_4 => "5100"
      )
      details.masked_number.should == "510510******5100"
    end
  end
end
