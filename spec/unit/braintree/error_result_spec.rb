require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::ErrorResult do
  describe "initialize" do
    it "ignores data other than params, errors, and message" do
      # so that we can add more data into the response in the future without breaking the client lib
      expect do
        Braintree::ErrorResult.new(
          :gateway,
          :params => "params",
          :errors => {:errors => []},
          :extra => "is ignored",
          :message => "foo bar",
        )
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
      result = Braintree::ErrorResult.new(:gateway, :params => "params", :errors => errors)
      expect(result.inspect).to eq("#<Braintree::ErrorResult params:{...} errors:<level1:[(code1) message], level1/level2:[(code2) message2]>>")
    end

    it "includes the credit_card_verification if there is one" do
      result = Braintree::ErrorResult.new(
        :gateway,
        :params => "params",
        :errors => {},
        :verification => {},
        :transaction => nil,
      )
      expect(result.inspect).to include("credit_card_verification: #<Braintree::CreditCardVerification amount: ")
    end

    it "does not include the credit_card_verification if there isn't one" do
      result = Braintree::ErrorResult.new(
        :gateway,
        :params => "params",
        :errors => {},
        :verification => nil,
        :transaction => nil,
      )
      expect(result.inspect).not_to include("credit_card_verification")
    end

    it "includes the transaction if there is one" do
      result = Braintree::ErrorResult.new(
        :gateway,
        :params => "params",
        :errors => {},
        :verification => nil,
        :transaction => {},
      )
      expect(result.inspect).to include("transaction: #<Braintree::Transaction id: ")
    end

    it "does not include the transaction if there isn't one" do
      result = Braintree::ErrorResult.new(
        :gateway,
        :params => "params",
        :errors => {},
        :verification => nil,
        :transaction => nil,
      )
      expect(result.inspect).not_to include("transaction")
    end
  end
end
