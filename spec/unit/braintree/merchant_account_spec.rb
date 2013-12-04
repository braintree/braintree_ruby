require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::MerchantAccount do
  describe "#inspect" do
    it "is a string representation of the merchant account" do
      account = Braintree::MerchantAccount._new(nil, :id => "merchant_account", :status => "active", :master_merchant_account => nil)

      account.inspect.should == "#<Braintree::MerchantAccount: id: \"merchant_account\", status: \"active\", master_merchant_account: nil>"
    end

    it "handles a master merchant account" do
      account = Braintree::MerchantAccount._new(
        nil,
        :id => "merchant_account",
        :status => "active",
        :master_merchant_account => {:id => "master_merchant_account", :status => "active", :master_merchant_account => nil}
      )

      master_merchant_account = "#<Braintree::MerchantAccount: id: \"master_merchant_account\", status: \"active\", master_merchant_account: nil>"
      account.inspect.should == "#<Braintree::MerchantAccount: id: \"merchant_account\", status: \"active\", master_merchant_account: #{master_merchant_account}>"
    end
  end
end

