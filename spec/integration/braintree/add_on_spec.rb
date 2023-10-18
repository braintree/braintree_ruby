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

      expect(add_on).not_to be_nil
      expect(add_on.amount).to eq(BigDecimal(expected[:amount]))
      expect(add_on.created_at).not_to be_nil
      expect(add_on.description).to eq(expected[:description])
      expect(add_on.kind).to eq(expected[:kind])
      expect(add_on.name).to eq(expected[:name])
      expect(add_on.never_expires).to eq(expected[:never_expires])
      expect(add_on.number_of_billing_cycles).to eq(expected[:number_of_billing_cycles])
      expect(add_on.updated_at).not_to be_nil
    end

    it "raises with a helpful error if public_key and private_key are not set" do
      gateway = Braintree::Gateway.new(
        :client_id => "client_id$#{Braintree::Configuration.environment}$integration_client_id",
        :client_secret => "client_secret$#{Braintree::Configuration.environment}$integration_client_secret",
        :logger => Logger.new("/dev/null"),
      )

      expect do
        gateway.add_on.all
      end.to raise_error(Braintree::ConfigurationError, /access_token or public_key and private_key are required/)
    end
  end
end
