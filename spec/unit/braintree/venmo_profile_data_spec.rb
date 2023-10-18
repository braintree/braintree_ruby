require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::VenmoProfileData do
  describe "self.new" do
    it "is protected" do
      expect do
        Braintree::VenmoProfileData.new
      end.to raise_error(NoMethodError, /protected method .new/)
    end
  end

  describe "self._new" do
    it "initializes the object with the appropriate attributes set" do

      params = {
        username: "a-username",
        first_name: "a-first-name",
        last_name: "a-last-name",
        phone_number: "12312312343",
        email: "a-email",
      }

      payment_method_customer_data_updated = Braintree::VenmoProfileData._new(params)

      expect(payment_method_customer_data_updated.username).to eq("a-username")
      expect(payment_method_customer_data_updated.first_name).to eq("a-first-name")
      expect(payment_method_customer_data_updated.last_name).to eq("a-last-name")
      expect(payment_method_customer_data_updated.phone_number).to eq("12312312343")
      expect(payment_method_customer_data_updated.email).to eq("a-email")
    end
  end
end
