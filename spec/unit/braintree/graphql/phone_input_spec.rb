require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")


describe Braintree::PhoneInput do
    let(:phone_input_data) do
    {
        country_phone_code: "1",
        phone_number: "555-123-4567",
        extension_number: "123"
    }
    end

    let(:partial_phone_input_data) do
    {
        country_phone_code: "1",
        phone_number: "555-123-4567"
    }
    end


    describe "#initialize" do
      it "initialize and sets the input keys to attrs variable" do
        phone_input = described_class.new(phone_input_data)

        expect(phone_input.attrs).to include(:country_phone_code)
        expect(phone_input.attrs).to include(:phone_number)
        expect(phone_input.attrs).to include(:extension_number)
        expect(phone_input.attrs.length).to eq(3)
      end
    end

    describe "inspect" do
      it "includes all phone input attributes" do
        phone_input = described_class.new(phone_input_data)
        output = phone_input.inspect

        expect(output).to include("country_phone_code:\"1\"")
        expect(output).to include("phone_number:\"555-123-4567\"")
        expect(output).to include("extension_number:\"123\"")
      end

      it "includes only specified phone input attributes" do
        phone_input = described_class.new(partial_phone_input_data)
        output = phone_input.inspect

        expect(output).to include("country_phone_code:\"1\"")
        expect(output).to include("phone_number:\"555-123-4567\"")
        expect(output).not_to include("extension_number")
      end
    end
end