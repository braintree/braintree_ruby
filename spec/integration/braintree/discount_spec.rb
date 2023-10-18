require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Discount do
  describe "self.all" do
    it "gets all discounts" do
      id = rand(36**8).to_s(36)

      expected = {
        :amount => "100.00",
        :description => "some description",
        :id => id,
        :kind => "discount",
        :name => "ruby_discount",
        :never_expires => false,
        :number_of_billing_cycles => 1
      }

      create_modification_for_tests(expected)

      discounts = Braintree::Discount.all
      discount = discounts.select { |discount| discount.id == id }.first

      expect(discount).not_to be_nil
      expect(discount.amount).to eq(BigDecimal(expected[:amount]))
      expect(discount.created_at).not_to be_nil
      expect(discount.description).to eq(expected[:description])
      expect(discount.kind).to eq(expected[:kind])
      expect(discount.name).to eq(expected[:name])
      expect(discount.never_expires).to eq(expected[:never_expires])
      expect(discount.number_of_billing_cycles).to eq(expected[:number_of_billing_cycles])
      expect(discount.updated_at).not_to be_nil
    end
  end
end
