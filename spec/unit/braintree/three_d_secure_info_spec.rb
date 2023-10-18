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
      expect(three_d_secure_info.acs_transaction_id).to eq("acs_id")
      expect(three_d_secure_info.cavv).to eq("cavvvalue")
      expect(three_d_secure_info.ds_transaction_id).to eq("dstrxid")
      expect(three_d_secure_info.eci_flag).to eq("06")
      expect(three_d_secure_info.enrolled).to eq("Y")
      expect(three_d_secure_info.liability_shift_possible).to eq(true)
      expect(three_d_secure_info.liability_shifted).to eq(true)
      expect(three_d_secure_info.pares_status).to eq("Y")
      expect(three_d_secure_info.status).to eq("authenticate_successful")
      expect(three_d_secure_info.three_d_secure_authentication_id).to eq("auth_id")
      expect(three_d_secure_info.three_d_secure_transaction_id).to eq("trans_id")
      expect(three_d_secure_info.three_d_secure_version).to eq("1.0.2")
      expect(three_d_secure_info.xid).to eq("xidvalue")
      expect(three_d_secure_info.lookup[:trans_status]).to eq("lookupstatus")
      expect(three_d_secure_info.lookup[:trans_status_reason]).to eq("lookupstatusreason")
      expect(three_d_secure_info.authentication[:trans_status]).to eq("authstatus")
      expect(three_d_secure_info.authentication[:trans_status_reason]).to eq("authstatusreason")
    end
  end

  describe "inspect" do
    it "prints the attributes" do
      expect(three_d_secure_info.inspect).to eq(%(#<ThreeDSecureInfo acs_transaction_id: "acs_id", authentication: {:trans_status=>"authstatus", :trans_status_reason=>"authstatusreason"}, cavv: "cavvvalue", ds_transaction_id: "dstrxid", eci_flag: "06", enrolled: "Y", liability_shift_possible: true, liability_shifted: true, lookup: {:trans_status=>"lookupstatus", :trans_status_reason=>"lookupstatusreason"}, pares_status: "Y", status: "authenticate_successful", three_d_secure_authentication_id: "auth_id", three_d_secure_transaction_id: "trans_id", three_d_secure_version: "1.0.2", xid: "xidvalue">))
    end
  end

  describe "liability_shifted" do
    it "is aliased to liability_shifted?" do
      expect(three_d_secure_info.liability_shifted?).to eq(true)
    end
  end

  describe "liability_shift_possible" do
    it "is aliased to liability_shift_possible?" do
      expect(three_d_secure_info.liability_shift_possible?).to eq(true)
    end
  end
end
