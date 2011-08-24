require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::AddOn do
  describe "self.all" do
    it "gets all add_ons" do
      id = rand(36**8).to_s(36)

      expected = {
        :amount => "100.00",
        :description => "some description",
        :id => id,
        :kind => "add_on",
        :name => "ruby_add_on",
        :never_expires => false,
        :number_of_billing_cycles => 1
      }

      create_modification_for_tests(expected)

      add_ons = Braintree::AddOn.all
      add_on = add_ons.select { |add_on| add_on.id == id }.first

      add_on.should_not be_nil
      add_on.amount.should == BigDecimal.new(expected[:amount])
      add_on.created_at.should_not be_nil
      add_on.description.should == expected[:description]
      add_on.kind.should == expected[:kind]
      add_on.name.should == expected[:name]
      add_on.never_expires.should == expected[:never_expires]
      add_on.number_of_billing_cycles.should == expected[:number_of_billing_cycles]
      add_on.updated_at.should_not be_nil
    end
  end
end
