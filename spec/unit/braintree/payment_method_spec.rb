require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::PaymentMethod do
  describe "find" do
    it "handles an unknown payment method type" do
      unknown_payment_method_type_response = {
        :unknown_payment_method => {
          :param_1 => "value 1",
          :param_2 => "value 2"
        }
      }

      http_instance = mock(:get => unknown_payment_method_type_response)
      Braintree::Http.stub(:new).and_return(http_instance)

      expect do
        result = Braintree::PaymentMethod.find("unknown_type_token")
        result.should be_nil
      end.to_not raise_error
    end
  end
end
