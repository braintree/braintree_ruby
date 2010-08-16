require File.dirname(__FILE__) + "/../spec_helper"

describe Braintree::Transaction do
  describe "self.create" do
    it "raises an exception if hash includes an invalid key" do
      expect do
        Braintree::Transaction.create(:amount => "Joe", :invalid_key => "foo")
      end.to raise_error(ArgumentError, "invalid keys: invalid_key")
    end
  end

  describe "self.create_from_transparent_redirect" do
    it "raises an exception if the query string is forged" do
      expect do
        Braintree::Transaction.create_from_transparent_redirect("http_status=200&forged=query_string")
      end.to raise_error(Braintree::ForgedQueryString)
    end
  end

  describe "self.create_transaction_url" do
    it "returns the url" do
      port = Braintree::Configuration.instantiate.port
      Braintree::Transaction.create_transaction_url.should == "http://localhost:#{port}/merchants/integration_merchant_id/transactions/all/create_via_transparent_redirect_request"
    end
  end

  describe "self.submit_for_settlement" do
    it "raises an ArgumentError if transaction_id is an invalid format" do
      expect do
        Braintree::Transaction.submit_for_settlement("invalid-transaction-id")
      end.to raise_error(ArgumentError, "transaction_id is invalid")
    end
  end

  describe "initialize" do
    it "sets up customer attributes in customer_details" do
      transaction = Braintree::Transaction._new(
        :gateway,
        :customer => {
          :id => "123",
          :first_name => "Adam",
          :last_name => "Taylor",
          :company => "Ledner LLC",
          :email => "adam.taylor@lednerllc.com",
          :website => "lednerllc.com",
          :phone => "1-999-652-4189 x56883",
          :fax => "012-161-8055"
        }
      )
      transaction.customer_details.id.should == "123"
      transaction.customer_details.first_name.should == "Adam"
      transaction.customer_details.last_name.should == "Taylor"
      transaction.customer_details.company.should == "Ledner LLC"
      transaction.customer_details.email.should == "adam.taylor@lednerllc.com"
      transaction.customer_details.website.should == "lednerllc.com"
      transaction.customer_details.phone.should == "1-999-652-4189 x56883"
      transaction.customer_details.fax.should == "012-161-8055"
    end

    it "sets up credit card attributes in credit_card_details" do
      transaction = Braintree::Transaction._new(
        :gateway,
        :credit_card => {
          :token => "mzg2",
          :bin => "411111",
          :last_4 => "1111",
          :card_type => "Visa",
          :expiration_month => "08",
          :expiration_year => "2009",
          :customer_location => "US"
        }
      )
      transaction.credit_card_details.token.should == "mzg2"
      transaction.credit_card_details.bin.should == "411111"
      transaction.credit_card_details.last_4.should == "1111"
      transaction.credit_card_details.card_type.should == "Visa"
      transaction.credit_card_details.expiration_month.should == "08"
      transaction.credit_card_details.expiration_year.should == "2009"
      transaction.credit_card_details.customer_location.should == "US"
    end

    it "sets up history attributes in status_history" do
      time = Time.utc(2010,1,14)
      transaction = Braintree::Transaction._new(
        :gateway,
        :status_history => [
          { :timestamp => time, :amount => "12.00", :transaction_source => "API",
            :user => "larry", :status => Braintree::Transaction::Status::Authorized },
          { :timestamp => Time.utc(2010,1,15), :amount => "12.00", :transaction_source => "API",
            :user => "curly", :status => "scheduled_for_settlement"}
        ])
      transaction.status_history.size.should == 2
      transaction.status_history[0].user.should == "larry"
      transaction.status_history[0].amount.should == "12.00"
      transaction.status_history[0].status.should == Braintree::Transaction::Status::Authorized
      transaction.status_history[0].transaction_source.should == "API"
      transaction.status_history[0].timestamp.should == time
      transaction.status_history[1].user.should == "curly"
    end

    it "handles receiving custom as an empty string" do
      transaction = Braintree::Transaction._new(
        :gateway,
        :custom => "\n    "
      )
    end

    it "accepts amount as either a String or a BigDecimal" do
      Braintree::Transaction._new(:gateway, :amount => "12.34").amount.should == BigDecimal.new("12.34")
      Braintree::Transaction._new(:gateway, :amount => BigDecimal.new("12.34")).amount.should == BigDecimal.new("12.34")
    end

    it "blows up if amount is not a string or BigDecimal" do
      expect {
        Braintree::Transaction._new(:gateway, :amount => 12.34)
      }.to raise_error(/Argument must be a String or BigDecimal/)
    end
  end

  describe "inspect" do
    it "includes the id, type, amount, and status first" do
      transaction = Braintree::Transaction._new(
        :gateway,
        :id => "1234",
        :type => "sale",
        :amount => "100.00",
        :status => Braintree::Transaction::Status::Authorized
      )
      output = transaction.inspect
      output.should include(%Q(#<Braintree::Transaction id: "1234", type: "sale", amount: "100.0", status: "authorized"))
    end
  end

  describe "==" do
    it "returns true for transactions with the same id" do
      first = Braintree::Transaction._new(:gateway, :id => 123)
      second = Braintree::Transaction._new(:gateway, :id => 123)

      first.should == second
      second.should == first
    end

    it "returns false for transactions with different ids" do
      first = Braintree::Transaction._new(:gateway, :id => 123)
      second = Braintree::Transaction._new(:gateway, :id => 124)

      first.should_not == second
      second.should_not == first
    end

    it "returns false when comparing to nil" do
      Braintree::Transaction._new(:gateway, {}).should_not == nil
    end

    it "returns false when comparing to non-transactions" do
      same_id_different_object = Object.new
      def same_id_different_object.id; 123; end
      transaction = Braintree::Transaction._new(:gateway, :id => 123)
      transaction.should_not == same_id_different_object
    end
  end

  describe "new" do
    it "is protected" do
      expect do
        Braintree::Transaction.new
      end.to raise_error(NoMethodError, /protected method .new/)
    end
  end

  describe "refunded?" do
    it "is true if the transaciton has been refunded" do
      transaction = Braintree::Transaction._new(:gateway, :refund_id => "123")
      transaction.refunded?.should == true
    end

    it "is false if the transaciton has not been refunded" do
      transaction = Braintree::Transaction._new(:gateway, :refund_id => nil)
      transaction.refunded?.should == false
    end
  end
end
