require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")


describe Braintree::CustomerSessionInput do
  let(:input_data) do
  {
    email: "test@example.com" ,
    phone: {
      country_phone_code: "1",
      phone_number: "555-123-4567",
      extension_number: "123",
    },
    user_agent: "Mozilla"
  }
  end

  describe "#initialize" do
    it "initializes with attributes" do
      input = Braintree::CustomerSessionInput.new(input_data)

      expect(input.attrs).to eq(input_data.keys)
      expect(input.email).to eq("test@example.com")
      expect(input.phone.country_phone_code).to eq("1")
      expect(input.phone.phone_number).to eq("555-123-4567")
      expect(input.phone.extension_number).to eq("123")
      expect(input.user_agent).to eq("Mozilla")
    end

    it "handles nil email" do
      attributes = {}
      input = Braintree::CustomerSessionInput.new(attributes)
      expect(input.email).to be_nil
    end
  end


  describe "#inspect" do
      it "returns a string representation of the object" do
        input = Braintree::CustomerSessionInput.new(input_data)
        expected_string = "#<Braintree::CustomerSessionInput email:\"test@example.com\" phone:#<Braintree::PhoneInput country_phone_code:\"1\" phone_number:\"555-123-4567\" extension_number:\"123\"> user_agent:\"Mozilla\">"
        expect(input.inspect).to eq(expected_string)

      end

      it "handles nil values" do
        attributes = {}
        input = Braintree::CustomerSessionInput.new(attributes)
        expected_string = "#<Braintree::CustomerSessionInput >"

        expect(input.inspect).to eq(expected_string)
      end

  end

  describe "#to_graphql_variables" do
    it "converts the input to graphql variables" do
      input = Braintree::CustomerSessionInput.new(input_data)
      expected_variables = {
        "email" => "test@example.com",
        "phone" => {
          "countryPhoneCode" => "1",
          "phoneNumber" => "555-123-4567",
          "extensionNumber" => "123"
        },
        "userAgent" => "Mozilla"
      }

      expect(input.to_graphql_variables).to eq(expected_variables)


    end

    it "handles nil values" do
        attributes = {}
        input = Braintree::CustomerSessionInput.new(attributes)
        expected_variables = {}

        expect(input.to_graphql_variables).to eq(expected_variables)
    end
  end
end