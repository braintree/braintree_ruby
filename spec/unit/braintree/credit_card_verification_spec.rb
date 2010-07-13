require File.dirname(__FILE__) + "/../spec_helper"

describe Braintree::CreditCardVerification do
  describe "inspect" do
    it "is better than the default inspect" do
      verification = Braintree::CreditCardVerification._new(
        :status => "verified",
        :avs_error_response_code => "I",
        :avs_postal_code_response_code => "I",
        :avs_street_address_response_code => "I",
        :cvv_response_code => "I",
        :processor_response_code => "2000",
        :processor_response_text => "Do Not Honor",
        :merchant_account_id => "some_id"
      )

      verification.inspect.should == %(#<Braintree::CreditCardVerification status: "verified", processor_response_code: "2000", processor_response_text: "Do Not Honor", cvv_response_code: "I", avs_error_response_code: "I", avs_postal_code_response_code: "I", avs_street_address_response_code: "I", merchant_account_id: "some_id", gateway_rejection_reason: nil>)
    end

    it "has a status" do
      verification = Braintree::CreditCardVerification._new(
        :status => "verified",
        :avs_error_response_code => "I",
        :avs_postal_code_response_code => "I",
        :avs_street_address_response_code => "I",
        :cvv_response_code => "I",
        :processor_response_code => "2000",
        :processor_response_text => "Do Not Honor",
        :merchant_account_id => "some_id"
      )

      verification.status.should == Braintree::CreditCardVerification::Status::VERIFIED
    end
  end
end

