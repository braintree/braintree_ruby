require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::PaymentMethodCustomerDataUpdatedMetadata do
  describe "self.new" do
    it "is protected" do
      expect do
        Braintree::PaymentMethodCustomerDataUpdatedMetadata.new
      end.to raise_error(NoMethodError, /protected method .new/)
    end
  end

  describe "self._new" do
    it "initializes the object with the appropriate attributes set" do

      params = {
        token: "a-token",
        payment_method: {
          venmo_account: {
            venmo_user_id: "venmo-user-id",
          },
        },
        datetime_updated: "2022-01-01T21:28:37Z",
        enriched_customer_data: {
          fields_updated: ["username"],
          profile_data: {
            username: "a-username",
            first_name: "a-first-name",
            last_name: "a-last-name",
            phone_number: "a-phone-number",
            email: "a-email",
          },
        },
      }

      payment_method_customer_data_updated = Braintree::PaymentMethodCustomerDataUpdatedMetadata._new(:gateway, params)

      expect(payment_method_customer_data_updated.token).to eq("a-token")
      expect(payment_method_customer_data_updated.datetime_updated).to eq("2022-01-01T21:28:37Z")
      expect(payment_method_customer_data_updated.payment_method).to be_a(Braintree::VenmoAccount)
      expect(payment_method_customer_data_updated.enriched_customer_data.profile_data.first_name).to eq("a-first-name")
      expect(payment_method_customer_data_updated.enriched_customer_data.profile_data.last_name).to eq("a-last-name")
      expect(payment_method_customer_data_updated.enriched_customer_data.fields_updated).to eq(["username"])
    end
  end
end
