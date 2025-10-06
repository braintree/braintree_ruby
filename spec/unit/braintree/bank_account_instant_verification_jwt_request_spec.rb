require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::BankAccountInstantVerificationJwtRequest do
  describe "to_graphql_variables" do
    it "includes all fields when present" do
      request = Braintree::BankAccountInstantVerificationJwtRequest.new(
        :business_name => "Test Business",
        :return_url => "https://example.com/success",
        :cancel_url => "https://example.com/cancel",
      )

      variables = request.to_graphql_variables

      expect(variables).not_to be_nil
      expect(variables).to have_key(:input)

      input = variables[:input]

      expect(input[:businessName]).to eq("Test Business")
      expect(input[:returnUrl]).to eq("https://example.com/success")
      expect(input[:cancelUrl]).to eq("https://example.com/cancel")
    end

    it "only includes non-null fields" do
      request = Braintree::BankAccountInstantVerificationJwtRequest.new(
        :business_name => "Test Business",
        :return_url => "https://example.com/success",
      )

      variables = request.to_graphql_variables

      input = variables[:input]

      expect(input[:businessName]).to eq("Test Business")
      expect(input[:returnUrl]).to eq("https://example.com/success")
      expect(input).not_to have_key(:cancelUrl)
    end

    it "handles empty request" do
      request = Braintree::BankAccountInstantVerificationJwtRequest.new

      variables = request.to_graphql_variables

      expect(variables).to eq({:input => {}})
    end
  end

describe "attribute accessors" do
  it "allows setting and getting all attributes and initializes with hash of attributes" do
    request = Braintree::BankAccountInstantVerificationJwtRequest.new(
      :business_name => "Test Business",
      :return_url => "https://example.com/success",
      :cancel_url => "https://example.com/cancel",
    )

    expect(request.business_name).to eq("Test Business")
    expect(request.return_url).to eq("https://example.com/success")
    expect(request.cancel_url).to eq("https://example.com/cancel")

    new_request = Braintree::BankAccountInstantVerificationJwtRequest.new

    new_request.business_name = "Updated Business"
    new_request.return_url = "https://example.com/updated"
    new_request.cancel_url = "https://example.com/updated-cancel"

    expect(new_request.business_name).to eq("Updated Business")
    expect(new_request.return_url).to eq("https://example.com/updated")
    expect(new_request.cancel_url).to eq("https://example.com/updated-cancel")
  end
end
end