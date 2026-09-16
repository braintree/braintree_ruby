require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::UsBankAccount do
  describe "default?" do
    it "is true if the us bank account is the default us bank account for the customer" do
      expect(Braintree::UsBankAccount._new(:gateway, :default => true).default?).to eq(true)
    end

    it "is false if the us bank account is not the default us bank account for the customer" do
      expect(Braintree::UsBankAccount._new(:gateway, :default => false).default?).to eq(false)
    end
  end

  describe "path traversal" do
    it "self.find raises an exception if the token is a traversal segment" do
      expect do
        Braintree::UsBankAccount.find("../payment_methods/credit_card/victim_token")
      end.to raise_error(ArgumentError, "token contains invalid characters")
    end
  end
end
