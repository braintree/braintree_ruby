require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::GooglePayDetails do
  it "initializes prepaid reloadable correctly" do
    card = Braintree::GooglePayDetails.new({:prepaid_reloadable => "No"})
    expect(card.prepaid_reloadable).to eq("No")
  end

  it "initializes business correctly" do
    card = Braintree::GooglePayDetails.new({:business => "No"})
    expect(card.business).to eq("No")
  end

  it "initializes consumer correctly" do
    card = Braintree::GooglePayDetails.new({:consumer => "No"})
    expect(card.consumer).to eq("No")
  end

  it "initializes corporate correctly" do
    card = Braintree::GooglePayDetails.new({:corporate => "No"})
    expect(card.corporate).to eq("No")
  end

  it "initializes purchase correctly" do
    card = Braintree::GooglePayDetails.new({:purchase => "No"})
    expect(card.purchase).to eq("No")
  end

  context "payment_account_reference" do
    it "returns the payment account reference when present" do
      details = Braintree::GooglePayDetails.new(
        :payment_account_reference => "V0010013019339005665779448477",
      )
      expect(details.payment_account_reference).to eq("V0010013019339005665779448477")
    end
  end
end
