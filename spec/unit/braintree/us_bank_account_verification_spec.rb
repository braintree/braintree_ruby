require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::UsBankAccountVerification do
  describe "inspect" do
    let(:verification) do
      Braintree::UsBankAccountVerification._new(
        :id => "some_verification_id",
        :status => Braintree::UsBankAccountVerification::Status::Verified,
        :verification_method => Braintree::UsBankAccountVerification::VerificationMethod::IndependentCheck,
        :verification_determined_at => "2018-02-28T12:01:01Z",
        :additional_processor_response => "some_invalid_processor_response",
      )
    end

    it "has a status" do
      expect(verification.status).to eq(Braintree::UsBankAccountVerification::Status::Verified)
    end

    it "has additional processor response" do
      expect(verification.additional_processor_response).to eq("some_invalid_processor_response")
    end
  end

  describe "self.confirm_micro_transfer_amounts" do
    it "raises error if passed empty string" do
      expect do
        Braintree::UsBankAccountVerification.confirm_micro_transfer_amounts("", [])
      end.to raise_error(ArgumentError)
    end

    it "raises error if passed empty string wth space" do
      expect do
        Braintree::UsBankAccountVerification.confirm_micro_transfer_amounts(" ", [])
      end.to raise_error(ArgumentError)
    end

    it "raises error if passed nil" do
      expect do
        Braintree::UsBankAccountVerification.confirm_micro_transfer_amounts(nil, [])
      end.to raise_error(ArgumentError)
    end

    it "raises error if passed non-array" do
      expect do
        Braintree::UsBankAccountVerification.confirm_micro_transfer_amounts(999, 123)
      end.to raise_error(ArgumentError)
    end
  end

  describe "self.find" do
    it "raises error if passed empty string" do
      expect do
        Braintree::UsBankAccountVerification.find("")
      end.to raise_error(ArgumentError)
    end

    it "raises error if passed empty string wth space" do
      expect do
        Braintree::UsBankAccountVerification.find(" ")
      end.to raise_error(ArgumentError)
    end

    it "raises error if passed nil" do
      expect do
        Braintree::UsBankAccountVerification.find(nil)
      end.to raise_error(ArgumentError)
    end
  end

  describe "==" do
    it "returns true for verifications with the same id" do
      first = Braintree::UsBankAccountVerification._new(:id => "123")
      second = Braintree::UsBankAccountVerification._new(:id => "123")

      expect(first).to eq(second)
      expect(second).to eq(first)
    end

    it "returns false for verifications with different ids" do
      first = Braintree::UsBankAccountVerification._new(:id => "123")
      second = Braintree::UsBankAccountVerification._new(:id => "124")

      expect(first).not_to eq(second)
      expect(second).not_to eq(first)
    end

    it "returns false when comparing to nil" do
      expect(Braintree::UsBankAccountVerification._new({})).not_to eq(nil)
    end

    it "returns false when comparing to non-verifications" do
      same_id_different_object = Object.new
      def same_id_different_object.id; "123"; end
      verification = Braintree::UsBankAccountVerification._new(:id => "123")
      expect(verification).not_to eq(same_id_different_object)
    end
  end
end
