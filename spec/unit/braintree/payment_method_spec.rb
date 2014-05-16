require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::PaymentMethod do
  describe "find" do
    it "handles an unknown payment method type" do
      unknown_response = {:unknown_payment_method => {:token => 1234, :default => true}}
      http_instance = mock(:get => unknown_response)
      Braintree::Http.stub(:new).and_return(http_instance)
      unknown_payment_method = Braintree::PaymentMethod.find("UNKNOWN_PAYMENT_METHOD_TOKEN")

      unknown_payment_method.token.should == 1234
      unknown_payment_method.default?.should be_true
    end
  end
end
