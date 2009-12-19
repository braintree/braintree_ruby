require File.dirname(__FILE__) + "/../spec_helper"

describe Braintree::Digest do
  describe "self.hexdigest" do
    it "returns the sha1 hmac of the input string (test case 6 from RFC 2202)" do
      begin
        original_key = Braintree::Configuration.private_key
        Braintree::Configuration.private_key = "\xaa" * 80
        data = "Test Using Larger Than Block-Size Key - Hash Key First"
        Braintree::Digest.hexdigest(data).should == "aa4ae5e15272d00e95705637ce8a3b55ed402112"
      ensure
        Braintree::Configuration.private_key = original_key
      end
    end

    it "returns the sha1 hmac of the input string (test case 7 from RFC 2202)" do
      begin
        original_key = Braintree::Configuration.private_key
        Braintree::Configuration.private_key = "\xaa" * 80
        data = "Test Using Larger Than Block-Size Key and Larger Than One Block-Size Data"
        Braintree::Digest.hexdigest(data).should == "e8e99d0f45237d786d6bbaa7965c7808bbff1a91"
      ensure
        Braintree::Configuration.private_key = original_key
      end
    end
  end
end

