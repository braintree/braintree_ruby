require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::ValidationError do
  describe "initialize" do
    it "works" do
      error = Braintree::ValidationError.new :attribute => "some model attribute", :code => 1, :message => "bad juju"
      expect(error.attribute).to eq("some model attribute")
      expect(error.code).to eq(1)
      expect(error.message).to eq("bad juju")
    end
  end

  describe "inspect" do
    it "is pretty" do
      error = Braintree::ValidationError.new :attribute => "number", :code => "123456", :message => "Number is bad juju."
      expect(error.inspect).to eq("#<Braintree::ValidationError (123456) Number is bad juju.>")
    end
  end
end
