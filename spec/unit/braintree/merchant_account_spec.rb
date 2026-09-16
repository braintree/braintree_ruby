require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::MerchantAccount do
  describe "path traversal" do
    it "self.find raises an exception if the merchant_account_id is a traversal segment" do
      expect do
        Braintree::MerchantAccount.find("../transactions/some_id/void")
      end.to raise_error(ArgumentError, "merchant_account_id contains invalid characters")
    end
  end
end
