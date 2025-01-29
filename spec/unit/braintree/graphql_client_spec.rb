require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::GraphQLClient do

  describe ".get_validation_errors" do
    it "returns nil if no errors" do
      expect(Braintree::GraphQLClient.get_validation_errors({})).to be_nil
    end

    it "returns nil if errors is not an array" do
      expect(Braintree::GraphQLClient.get_validation_errors({:errors => "string"})).to be_nil
    end

    it "returns validation errors" do
      response = {
        :errors => [
          {:message => "Invalid input", :extensions => {:legacyCode => "81803"}},
          {:message => "Another error", :extensions => {:legacyCode => "91903"}}
        ]
      }
      expected_errors = {
        :errors => [
          {:attribute => "", :code => "81803", :message => "Invalid input"},
          {:attribute => "", :code => "91903", :message => "Another error"}
        ]
      }
      expect(Braintree::GraphQLClient.get_validation_errors(response)).to eq(expected_errors)
    end


    it "handles missing legacyCode" do
      response = {:errors => [{:message => "Invalid input"}]}
      expected_errors = {:errors => [{:attribute => "", :code => nil, :message => "Invalid input"}]}
      expect(Braintree::GraphQLClient.get_validation_errors(response)).to eq(expected_errors)
    end
  end
end
