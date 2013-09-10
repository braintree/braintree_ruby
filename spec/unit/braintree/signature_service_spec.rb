require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

class FakeDigest
  def self.hexdigest(key, string)
    "#{string}_signed_with_#{key}"
  end
end

describe Braintree::SignatureService do
  describe "sign" do
    it "signs and URL encodes data with it's key" do
      service = Braintree::SignatureService.new("my_key", FakeDigest)

      service.sign(:foo => "bar").should == "foo=bar_signed_with_my_key|foo=bar"
    end
  end

  describe "hash" do
    it "hashes the string with it's key" do
      Braintree::SignatureService.new("my_key", FakeDigest).hash("foo").should == "foo_signed_with_my_key"
    end
  end
end
