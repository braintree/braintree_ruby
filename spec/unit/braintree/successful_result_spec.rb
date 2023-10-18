require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::SuccessfulResult do
  describe "initialize" do
    it "sets instance variables from the values in the hash" do
      result = Braintree::SuccessfulResult.new(
        :transaction => "transaction_value",
        :credit_card => "credit_card_value",
      )
      expect(result.success?).to eq(true)
      expect(result.transaction).to eq("transaction_value")
      expect(result.credit_card).to eq("credit_card_value")
    end

    it "can be initialized without any values" do
      result = Braintree::SuccessfulResult.new
      expect(result.success?).to eq(true)
    end
  end

  describe "inspect" do
    it "is pretty" do
      result = Braintree::SuccessfulResult.new(:transaction => "transaction_value")
      expect(result.inspect).to eq("#<Braintree::SuccessfulResult transaction:\"transaction_value\">")
    end
  end
end
