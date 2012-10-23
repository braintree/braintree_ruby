require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

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

      verification.inspect.should == %(#<Braintree::CreditCardVerification status: "verified", processor_response_code: "2000", processor_response_text: "Do Not Honor", cvv_response_code: "I", avs_error_response_code: "I", avs_postal_code_response_code: "I", avs_street_address_response_code: "I", merchant_account_id: "some_id", gateway_rejection_reason: nil, id: nil, credit_card: nil, billing: nil, created_at: nil>)
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

  describe "self.find" do
    it "raises error if passed empty string" do
      expect do
        Braintree::CreditCardVerification.find("")
      end.to raise_error(ArgumentError)
    end

    it "raises error if passed empty string wth space" do
      expect do
        Braintree::CreditCardVerification.find(" ")
      end.to raise_error(ArgumentError)
    end

    it "raises error if passed nil" do
      expect do
        Braintree::CreditCardVerification.find(nil)
      end.to raise_error(ArgumentError)
    end
  end

  describe "==" do
    it "returns true for verifications with the same id" do
      first = Braintree::CreditCardVerification._new(:id => 123)
      second = Braintree::CreditCardVerification._new(:id => 123)

      first.should == second
      second.should == first
    end

    it "returns false for verifications with different ids" do
      first = Braintree::CreditCardVerification._new(:id => 123)
      second = Braintree::CreditCardVerification._new(:id => 124)

      first.should_not == second
      second.should_not == first
    end

    it "returns false when comparing to nil" do
      Braintree::CreditCardVerification._new({}).should_not == nil
    end

    it "returns false when comparing to non-verifications" do
      same_id_different_object = Object.new
      def same_id_different_object.id; 123; end
      verification = Braintree::CreditCardVerification._new(:id => 123)
      verification.should_not == same_id_different_object
    end
  end
end

