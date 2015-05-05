require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::ThreeDSecureInfo do
  let(:three_d_secure_info) {
    Braintree::ThreeDSecureInfo.new(
      :enrolled => "Y",
      :liability_shifted => true,
      :liability_shift_possible => true,
      :cavv => "cavvvalue",
      :xid => "xidvalue",
      :status => "authenticate_successful",
    )
  }

  describe "#initialize" do
    it "sets attributes" do
      three_d_secure_info.enrolled.should == "Y"
      three_d_secure_info.xid.should == "xidvalue"
      three_d_secure_info.cavv.should == "cavvvalue"
      three_d_secure_info.status.should == "authenticate_successful"
      three_d_secure_info.liability_shifted.should == true
      three_d_secure_info.liability_shift_possible.should == true
    end
  end

  describe "inspect" do
    it "prints the attributes" do
      three_d_secure_info.inspect.should == %(#<ThreeDSecureInfo enrolled: "Y", liability_shifted: true, liability_shift_possible: true, xid: "xidvalue", cavv: "cavvvalue", status: "authenticate_successful">)
    end
  end

  describe "liability_shifted" do
    it "is aliased to liability_shifted?" do
      three_d_secure_info.liability_shifted?.should == true
    end
  end

  describe "liability_shift_possible" do
    it "is aliased to liability_shift_possible?" do
      three_d_secure_info.liability_shift_possible?.should == true
    end
  end
end
