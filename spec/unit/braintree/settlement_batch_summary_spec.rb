require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::SettlementBatchSummary do
  describe 'self.generate' do
    it "raises an exception if hash includes an invalid key" do
      expect do
        Braintree::SettlementBatchSummary.generate('2011-08-09', :invalid => 'invalid')
      end.to raise_error(ArgumentError, "invalid keys: invalid")
    end
  end
end

