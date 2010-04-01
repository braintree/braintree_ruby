require File.dirname(__FILE__) + "/../spec_helper"

describe Braintree::CreditCard do
  describe "self.create" do
    it "raises an exception if attributes contain an invalid key" do
      expect do
        Braintree::CreditCard.create(:invalid_key => 'val')
      end.to raise_error(ArgumentError, "invalid keys: invalid_key")
    end
  end

  describe "self.create_signature" do
    it "should include customer_id" do
      Braintree::CreditCard._create_signature.should include(:customer_id)
    end
  end

  describe "self.update_signature" do
    it "should not include customer_id" do
      Braintree::CreditCard._update_signature.should_not include(:customer_id)
    end
  end

  describe "self.create_from_transparent_redirect" do
    it "raises an exception if the query string is forged" do
      expect do
        Braintree::CreditCard.create_from_transparent_redirect("forged=query_string")
      end.to raise_error(Braintree::ForgedQueryString)
    end
  end

  describe "self.create_credit_card_url" do
    it "returns the url" do
      port = Braintree::Configuration.port
      Braintree::CreditCard.create_credit_card_url.should == "http://localhost:#{port}/merchants/integration_merchant_id/payment_methods/all/create_via_transparent_redirect_request"
    end
  end

  describe "==" do
    it "returns true if given a credit card with the same token" do
      first = Braintree::CreditCard._new(:token => 123)
      second = Braintree::CreditCard._new(:token => 123)

      first.should == second
      second.should == first
    end

    it "returns false if given a credit card with a different token" do
      first = Braintree::CreditCard._new(:token => 123)
      second = Braintree::CreditCard._new(:token => 124)

      first.should_not == second
      second.should_not == first
    end

    it "returns false if not given a credit card" do
      credit_card = Braintree::CreditCard._new(:token => 123)
      credit_card.should_not == "not a credit card"
    end
  end

  describe "default?" do
    it "is true if the credit card is the default credit card for the customer" do
      Braintree::CreditCard._new(:default => true).default?.should == true
    end

    it "is false if the credit card is not the default credit card for the customer" do
      Braintree::CreditCard._new(:default => false).default?.should == false
    end
  end

  describe "expired?" do
    it "is true if the payment method is this year and the month has passed" do
      SpecHelper.stub_time_dot_now(Time.mktime(2009, 10, 20)) do
        expired_pm = Braintree::CreditCard._new(:expiration_month => "09", :expiration_year => "2009")
        expired_pm.expired?.should == true
      end
    end

    it "is true if the payment method is in a previous year" do
      expired_pm = Braintree::CreditCard._new(:expiration_month => "12", :expiration_year => (Time.now.year - 1).to_s)
      expired_pm.expired?.should == true
    end

    it "is false if the payment method is not expired" do
      not_expired_pm = Braintree::CreditCard._new(:expiration_month => "01", :expiration_year => (Time.now.year + 1).to_s)
      not_expired_pm.expired?.should == false
    end
  end

  describe "inspect" do
    it "includes the token first" do
      output = Braintree::CreditCard._new(:token => "cc123").inspect
      output.should include("#<Braintree::CreditCard token: \"cc123\",")
    end

    it "includes all customer attributes" do
      credit_card = Braintree::CreditCard._new(
        :bin => "411111",
        :card_type => "Visa",
        :cardholder_name => "John Miller",
        :created_at => Time.now,
        :customer_id => "cid1",
        :expiration_month => "01",
        :expiration_year => "2020",
        :last_4 => "1111",
        :token => "tok1",
        :updated_at => Time.now
      )
      output = credit_card.inspect
      output.should include(%q(bin: "411111"))
      output.should include(%q(card_type: "Visa"))
      output.should include(%q(cardholder_name: "John Miller"))

      output.should include(%q(customer_id: "cid1"))
      output.should include(%q(expiration_month: "01"))
      output.should include(%q(expiration_year: "2020"))
      output.should include(%q(last_4: "1111"))
      output.should include(%q(token: "tok1"))
      output.should include(%Q(updated_at: #{credit_card.updated_at.inspect}))
      output.should include(%Q(created_at: #{credit_card.created_at.inspect}))
    end
  end

  describe "masked_number" do
    it "uses the bin and last_4 to build the masked number" do
      credit_card = Braintree::CreditCard._new(
        :bin => "510510",
        :last_4 => "5100"
      )
      credit_card.masked_number.should == "510510******5100"
    end
  end

  describe "self.update" do
    it "raises an exception if attributes contain an invalid key" do
      expect do
        Braintree::CreditCard._new({}).update(:invalid_key => 'val')
      end.to raise_error(ArgumentError, "invalid keys: invalid_key")
    end
  end

  describe "self.new" do
    it "is protected" do
      expect do
        Braintree::CreditCard.new
      end.to raise_error(NoMethodError, /protected method .new/)
    end
  end
end
