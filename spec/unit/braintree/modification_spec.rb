require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Modification do
  it "converts string amount" do
    expect(Braintree::Modification._new(:amount => "100.00").amount).to eq(BigDecimal("100.00"))
  end
end
