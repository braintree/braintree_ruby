require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::PaymentMethodNonceDetailsPayerInfo do
  let(:payment_method_nonce_details_payer_info) {
    Braintree::PaymentMethodNonceDetailsPayerInfo.new(
      :billing_agreement_id => "billing-agreement-id",
      :country_code => "US",
      :email => "test@example.com",
      :first_name => "First",
      :last_name => "Last",
      :payer_id => "payer-id",
    )
  }

  describe "#initialize" do
    it "sets attributes" do
      payment_method_nonce_details_payer_info.billing_agreement_id.should == "billing-agreement-id"
      payment_method_nonce_details_payer_info.country_code.should == "US"
      payment_method_nonce_details_payer_info.email.should == "test@example.com"
      payment_method_nonce_details_payer_info.first_name.should == "First"
      payment_method_nonce_details_payer_info.last_name.should == "Last"
      payment_method_nonce_details_payer_info.payer_id.should == "payer-id"
    end
  end

  describe "inspect" do
    it "prints the attributes" do
      payment_method_nonce_details_payer_info.inspect.should == %(#<PaymentMethodNonceDetailsPayerInfo billing_agreement_id: \"billing-agreement-id\", country_code: \"US\", email: \"test@example.com\", first_name: \"First\", last_name: \"Last\", payer_id: \"payer-id\">)
    end
  end
end
