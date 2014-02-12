require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Transfer do
  describe "new" do
    it "is protected" do
      expect do
        Braintree::Transfer.new
      end.to raise_error(NoMethodError, /protected method .new/)
    end
  end
end
