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

  describe "inspect" do
    it "inspects" do
      details = Braintree::Transaction::CreditCardDetails.new(
        :bin => "123456",
        :card_type => "Visa",
        :cardholder_name => "The Cardholder",
        :expiration_month => "05",
        :expiration_year => "2012",
        :last_4 => "6789",
        :token => "token",
        :customer_location => "US"
      )
      details.inspect.should == %(#<token: "token", bin: "123456", last_4: "6789", card_type: "Visa", expiration_date: "05/2012", cardholder_name: "The Cardholder", customer_location: "US">)
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
