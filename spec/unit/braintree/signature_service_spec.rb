require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

class FakeDigest
  def self.hexdigest(key, string)
    "#{string}_signed_with_#{key}"
  end
end

describe Braintree::SignatureService do
  describe "sign" do
    it "signs the data with its key" do
      service = Braintree::SignatureService.new("my_key", FakeDigest)

      expect(service.sign(:foo => "foo bar")).to eq("foo=foo+bar_signed_with_my_key|foo=foo+bar")
    end
  end

  describe "hash" do
    it "hashes the string with its key" do
      expect(Braintree::SignatureService.new("my_key", FakeDigest).hash("foo")).to eq("foo_signed_with_my_key")
    end
  end
end
