require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::GooglePayDetails do
  it "initializes prepaid reloadable correctly" do
    card = Braintree::GooglePayDetails._new(:gateway, {:prepaid_reloadable => "No"})
    expect(card.prepaid_reloadable).to eq("No")
  end
end
