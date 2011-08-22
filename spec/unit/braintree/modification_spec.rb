require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Modification do
  it "has all fields" do
    expected = {
      :created_at => Time.now,
      :description => "some description",
      :id => "modification_id",
      :kind => "a kind",
      :merchant_id => "test_merchant_id",
      :name => "test modification",
      :never_expires => "true",
      :number_of_billing_cycles => 0,
      :quantity => 1,
      :updated_at => Time.now
    }
    modification = Braintree::Modification._new(expected)

    expected.each do |key,value|
      modification.send(key).should == value
    end
  end

  it "converts string amount" do
    Braintree::Modification._new(:amount => "100").amount.should == BigDecimal.new("100")
  end
end
