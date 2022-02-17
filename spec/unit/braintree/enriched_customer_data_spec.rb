require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::EnrichedCustomerData do
  describe "self.new" do
    it "is protected" do
      expect do
        Braintree::EnrichedCustomerData.new
      end.to raise_error(NoMethodError, /protected method .new/)
    end
  end

  describe "self._new" do
    it "initializes the object with the appropriate attributes set" do

      params = {
        fields_updated: ["username"],
        profile_data: {
          username: "a-username",
          first_name: "a-first-name",
          last_name: "a-last-name",
          phone_number: "a-phone-number",
          email: "a-email",
        },
      }

      payment_method_customer_data_updated = Braintree::EnrichedCustomerData._new(params)

      payment_method_customer_data_updated.profile_data.should be_a(Braintree::VenmoProfileData)
      payment_method_customer_data_updated.fields_updated.should eq(["username"])
    end
  end
end
