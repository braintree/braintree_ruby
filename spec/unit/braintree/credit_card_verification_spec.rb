require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::CreditCardVerification do
  describe "inspect" do
    it "is better than the default inspect" do
      verification = Braintree::CreditCardVerification._new(
        :status => "verified",
        :amount => "12.45",
        :ani_first_name_response_code => "I",
        :ani_last_name_response_code => "I",
        :currency_iso_code => "USD",
        :avs_error_response_code => "I",
        :avs_postal_code_response_code => "I",
        :avs_street_address_response_code => "I",
        :cvv_response_code => "I",
        :processor_response_code => "2000",
        :processor_response_text => "Do Not Honor",
        :merchant_account_id => "some_id",
        :network_response_code => "05",
        :network_response_text => "Do not Honor",
      )
      expect(verification.inspect).to eq(%(#<Braintree::CreditCardVerification amount: "12.45", ani_first_name_response_code: "I", ani_last_name_response_code: "I", avs_error_response_code: "I", avs_postal_code_response_code: "I", avs_street_address_response_code: "I", billing: nil, created_at: nil, credit_card: nil, currency_iso_code: "USD", cvv_response_code: "I", gateway_rejection_reason: nil, id: nil, merchant_account_id: "some_id", network_response_code: "05", network_response_text: "Do not Honor", processor_response_code: "2000", processor_response_text: "Do Not Honor", status: "verified">))
    end

    it "has a status" do
      verification = Braintree::CreditCardVerification._new(
        :status => "verified",
        :avs_error_response_code => "I",
        :avs_postal_code_response_code => "I",
        :avs_street_address_response_code => "I",
        :cvv_response_code => "I",
        :processor_response_code => "2000",
        :processor_response_text => "Do Not Honor",
        :merchant_account_id => "some_id",
      )

      expect(verification.status).to eq(Braintree::CreditCardVerification::Status::Verified)
    end
  end

  it "accepts ani name reponse codes" do
    verification = Braintree::CreditCardVerification._new(
      :ani_first_name_response_code => "M",
      :ani_last_name_response_code => "M",
    )

    expect(verification.ani_first_name_response_code).to eq("M")
    expect(verification.ani_last_name_response_code).to eq("M")
  end

  it "accepts amount as either a String or BigDecimal" do
    expect(Braintree::CreditCardVerification._new(:amount => "12.34").amount).to eq(BigDecimal("12.34"))
    expect(Braintree::CreditCardVerification._new(:amount => BigDecimal("12.34")).amount).to eq(BigDecimal("12.34"))
  end

  it "accepts network_transaction_id" do
    verification = Braintree::CreditCardVerification._new(
      :network_transaction_id => "123456789012345",
    )
    expect(verification.network_transaction_id).to eq "123456789012345"
  end

  describe "self.create" do
    it "rejects invalid parameters" do
      expect do
        Braintree::CreditCardVerification.create(:invalid_key => 4, :credit_card => {:number => "number"})
      end.to raise_error(ArgumentError, "invalid keys: invalid_key")
    end

    it "rejects parameters that are only valid for 'payment methods create'" do
      expect do
        Braintree::CreditCardVerification.create(:credit_card => {:options => {:verify_card => true}})
      end.to raise_error(ArgumentError, "invalid keys: credit_card[options][verify_card]")
    end
  end

  describe "self.find" do
    it "raises error if passed empty string" do
      expect do
        Braintree::CreditCardVerification.find("")
      end.to raise_error(ArgumentError)
    end

    it "raises error if passed empty string wth space" do
      expect do
        Braintree::CreditCardVerification.find(" ")
      end.to raise_error(ArgumentError)
    end

    it "raises error if passed nil" do
      expect do
        Braintree::CreditCardVerification.find(nil)
      end.to raise_error(ArgumentError)
    end
  end

  describe "==" do
    it "returns true for verifications with the same id" do
      first = Braintree::CreditCardVerification._new(:id => 123)
      second = Braintree::CreditCardVerification._new(:id => 123)

      expect(first).to eq(second)
      expect(second).to eq(first)
    end

    it "returns false for verifications with different ids" do
      first = Braintree::CreditCardVerification._new(:id => 123)
      second = Braintree::CreditCardVerification._new(:id => 124)

      expect(first).not_to eq(second)
      expect(second).not_to eq(first)
    end

    it "returns false when comparing to nil" do
      expect(Braintree::CreditCardVerification._new({})).not_to eq(nil)
    end

    it "returns false when comparing to non-verifications" do
      same_id_different_object = Object.new
      def same_id_different_object.id; 123; end
      verification = Braintree::CreditCardVerification._new(:id => 123)
      expect(verification).not_to eq(same_id_different_object)
    end
  end

  describe "risk_data" do
    it "initializes a RiskData object" do
      verification = Braintree::CreditCardVerification._new(:risk_data => {
        :id => "123",
        :decision => "WOO YOU WON $1000 dollars",
        :decision_reasons => ["reason"],
        :device_data_captured => true,
        :fraud_service_provider => "paypal_fraud_protection",
        :transaction_risk_score => "12",
      })

      expect(verification.risk_data.id).to eq("123")
      expect(verification.risk_data.decision).to eq("WOO YOU WON $1000 dollars")
      expect(verification.risk_data.decision_reasons).to eq(["reason"])
      expect(verification.risk_data.device_data_captured).to eq(true)
      expect(verification.risk_data.fraud_service_provider).to eq("paypal_fraud_protection")
      expect(verification.risk_data.transaction_risk_score).to eq("12")
    end

    it "handles a nil risk_data" do
      verification = Braintree::CreditCardVerification._new(:risk_data => nil)
      expect(verification.risk_data).to be_nil
    end
  end

  describe "network responses" do
    it "accepts network_response_code and network_response_text" do
      verification = Braintree::CreditCardVerification._new(
        :network_response_code => "00",
        :network_response_text => "Successful approval/completion or V.I.P. PIN verification is successful",
      )

      expect(verification.network_response_code).to eq("00")
      expect(verification.network_response_text).to eq("Successful approval/completion or V.I.P. PIN verification is successful")
    end
  end

  describe "credit_card with payment_account_reference" do
    it "includes payment_account_reference in credit_card hash when present" do
      verification = Braintree::CreditCardVerification._new(
        :status => "verified",
        :credit_card => {
          :bin => "401288",
          :last_4 => "1881",
          :card_type => "Visa",
          :payment_account_reference => "V0010013019339005665779448477"
        },
      )

      expect(verification.credit_card).to be_a(Hash)
      expect(verification.credit_card[:payment_account_reference]).to eq("V0010013019339005665779448477")
    end
  end
end
