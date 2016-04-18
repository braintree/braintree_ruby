require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::PaymentMethod do
  describe "find" do
    it "handles an unknown payment method type" do
      unknown_response = {:unknown_payment_method => {:token => 1234, :default => true}}
      http_instance = double(:get => unknown_response)
      Braintree::Http.stub(:new).and_return(http_instance)
      unknown_payment_method = Braintree::PaymentMethod.find("UNKNOWN_PAYMENT_METHOD_TOKEN")

      unknown_payment_method.token.should == 1234
      unknown_payment_method.default?.should be(true)
    end
  end

  describe "update" do
    it "handles an unknown payment method type" do
      unknown_response = {:unknown_payment_method => {:token => 1234, :default => true}}
      http_instance = double(:put => unknown_response)
      Braintree::Http.stub(:new).and_return(http_instance)
      result = Braintree::PaymentMethod.update(:unknown,
        {:options => {:make_default => true}})

      result.should be_success
      result.payment_method.token.should == 1234
      result.payment_method.should be_instance_of(Braintree::UnknownPaymentMethod)
    end
  end

  describe "timestamps" do
    it "exposes created_at and updated_at" do
      now = Time.now
      paypal_account = Braintree::PayPalAccount._new(:gateway, :updated_at => now, :created_at => now)

      paypal_account.created_at.should == now
      paypal_account.updated_at.should == now
    end
  end

  describe "self.grant" do
    it "raises error if passed empty string" do
      expect do
        Braintree::PaymentMethod.grant("", false)
      end.to raise_error(ArgumentError)
    end

    it "raises error if passed invalid string" do
      expect do
        Braintree::PaymentMethod.grant("\t", false)
      end.to raise_error(ArgumentError)
    end

    it "raises error if passed nil" do
      expect do
        Braintree::PaymentMethod.grant(nil, false)
      end.to raise_error(ArgumentError)
    end

    it "does not raise an error if token does not respond to strip" do
      Braintree::Http.stub(:new).and_return double.as_null_object
      expect do
        Braintree::PaymentMethod.grant(8675309, false)
      end.to_not raise_error
    end
  end

  describe "self.revoke" do
    it "raises error if passed empty string" do
      expect do
        Braintree::PaymentMethod.revoke("")
      end.to raise_error(ArgumentError)
    end

    it "raises error if passed invalid string" do
      expect do
        Braintree::PaymentMethod.revoke("\t")
      end.to raise_error(ArgumentError)
    end

    it "raises error if passed nil" do
      expect do
        Braintree::PaymentMethod.revoke(nil)
      end.to raise_error(ArgumentError)
    end

    it "does not raise an error if token does not respond to strip" do
      Braintree::Http.stub(:new).and_return double.as_null_object
      expect do
        Braintree::PaymentMethod.revoke(8675309)
      end.to_not raise_error
    end
  end
end
