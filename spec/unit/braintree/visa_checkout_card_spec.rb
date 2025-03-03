require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::VisaCheckoutCard do
  it "initializes prepaid reloadable correctly" do
    card = Braintree::VisaCheckoutCard._new(:gateway, {:prepaid_reloadable => "No"})
    expect(card.prepaid_reloadable).to eq("No")
  end
end
