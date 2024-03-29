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
end
