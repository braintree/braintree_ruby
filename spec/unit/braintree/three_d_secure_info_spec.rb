require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::ThreeDSecureInfo do
  let(:three_d_secure_info) {
    Braintree::ThreeDSecureInfo.new(
      :acs_transaction_id => "acs_id",
      :cavv => "cavvvalue",
      :ds_transaction_id => "dstrxid",
      :eci_flag => "06",
      :enrolled => "Y",
      :liability_shift_possible => true,
      :liability_shifted => true,
      :pares_status => "Y",
      :status => "authenticate_successful",
      :three_d_secure_authentication_id => "auth_id",
      :three_d_secure_transaction_id => "trans_id",
      :three_d_secure_version => "1.0.2",
      :xid => "xidvalue",
      :authentication => {
        :trans_status => "authstatus",
        :trans_status_reason => "authstatusreason"
      },
      :lookup => {
        :trans_status => "lookupstatus",
        :trans_status_reason => "lookupstatusreason"
      },
    )
  }

  describe "#initialize" do
    it "sets attributes" do
      three_d_secure_info.acs_transaction_id.should == "acs_id"
      three_d_secure_info.cavv.should == "cavvvalue"
      three_d_secure_info.ds_transaction_id.should == "dstrxid"
      three_d_secure_info.eci_flag.should == "06"
      three_d_secure_info.enrolled.should == "Y"
      three_d_secure_info.liability_shift_possible.should == true
      three_d_secure_info.liability_shifted.should == true
      three_d_secure_info.pares_status.should == "Y"
      three_d_secure_info.status.should == "authenticate_successful"
      three_d_secure_info.three_d_secure_authentication_id.should == "auth_id"
      three_d_secure_info.three_d_secure_transaction_id.should == "trans_id"
      three_d_secure_info.three_d_secure_version.should == "1.0.2"
      three_d_secure_info.xid.should == "xidvalue"
      three_d_secure_info.lookup[:trans_status].should == "lookupstatus"
      three_d_secure_info.lookup[:trans_status_reason].should == "lookupstatusreason"
      three_d_secure_info.authentication[:trans_status].should == "authstatus"
      three_d_secure_info.authentication[:trans_status_reason].should == "authstatusreason"
    end
  end

  describe "inspect" do
    it "prints the attributes" do
      three_d_secure_info.inspect.should == %(#<ThreeDSecureInfo acs_transaction_id: "acs_id", authentication: {:trans_status=>"authstatus", :trans_status_reason=>"authstatusreason"}, cavv: "cavvvalue", ds_transaction_id: "dstrxid", eci_flag: "06", enrolled: "Y", liability_shift_possible: true, liability_shifted: true, lookup: {:trans_status=>"lookupstatus", :trans_status_reason=>"lookupstatusreason"}, pares_status: "Y", status: "authenticate_successful", three_d_secure_authentication_id: "auth_id", three_d_secure_transaction_id: "trans_id", three_d_secure_version: "1.0.2", xid: "xidvalue">)
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
