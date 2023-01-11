require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::SepaDirectDebitAccountNonceDetails do
  subject do
    described_class.new(
      :bank_reference_token => "a-bank-reference-token",
      :last_4 => "abcd",
      :mandate_type => "ONE_OFF",
      :merchant_or_partner_customer_id => "a-mp-customer-id",
    )
  end

  describe "#initialize" do
    it "sets attributes" do
      is_expected.to have_attributes(
        :bank_reference_token => "a-bank-reference-token",
        :last_4 => "abcd",
        :mandate_type => "ONE_OFF",
        :merchant_or_partner_customer_id => "a-mp-customer-id",
      )
    end
  end

  describe "inspect" do
    it "prints the attributes" do
      subject.inspect.should == %(#<SepaDirectDebitAccountNonceDetailsbank_reference_token: "a-bank-reference-token", last_4: "abcd", mandate_type: "ONE_OFF", merchant_or_partner_customer_id: "a-mp-customer-id">)
    end
  end
end
