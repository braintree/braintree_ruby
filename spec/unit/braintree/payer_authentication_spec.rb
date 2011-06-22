require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::PayerAuthentication do
  describe "id" do
    it "returns the given id" do
      payer_authentication = Braintree::PayerAuthentication._new(
        :gateway,
        :id => :test_id
      )

      payer_authentication.id.should == :test_id
    end
  end

  describe "post_params" do
    it "returns the given post params" do
      payer_authentication = Braintree::PayerAuthentication._new(
        :gateway,
        :post_params => [{:name => 'imaname', :value => 'andimavalue'}]
      )

      post_param = payer_authentication.post_params.first
      post_param.name.should == 'imaname'
      post_param.value.should == 'andimavalue'
    end
  end

  describe "post_url" do
    it "returns the given post url" do
      payer_authentication = Braintree::PayerAuthentication._new(
        :gateway,
        :post_url => "http://example.com"
      )

      payer_authentication.post_url.should == "http://example.com"
    end
  end
end
