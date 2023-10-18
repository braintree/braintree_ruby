require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::BaseModule do
  describe "return_object_or_raise" do
    it "inspects the error_result when inspecting the exception" do
      result = Braintree::ErrorResult.new(:gateway, :errors => {})
      begin
        klass = Class.new { include Braintree::BaseModule }
        klass.return_object_or_raise(:obj) { result }
      rescue Braintree::ValidationsFailed => ex
      end
      expect(ex).not_to eq(nil)
      expect(ex.error_result).to eq(result)
      expect(ex.inspect).to include(result.inspect)
      expect(ex.to_s).to include(result.inspect)
    end
  end
end
