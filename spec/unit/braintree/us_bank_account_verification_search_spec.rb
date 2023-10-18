require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Braintree
  describe UsBankAccountVerificationSearch do
    context "verification method" do
      it "allows All verification methods" do
        search = UsBankAccountVerificationSearch.new

        expect do
          search.verification_method.in(
            *Braintree::UsBankAccountVerification::VerificationMethod::All,
          )
        end.not_to raise_error
      end
    end

    context "id" do
      it "is" do
        search = UsBankAccountVerificationSearch.new
        search.id.is "v_id"

        expect(search.to_hash).to eq({:id => {:is => "v_id"}})
      end
    end

    context "ids" do
      it "correctly builds a hash with ids" do
        search = UsBankAccountVerificationSearch.new
        search.ids.in("id1", "id2")

        expect(search.to_hash).to eq({:ids => ["id1", "id2"]})
      end
    end

    context "account_holder_name" do
      it "is" do
        search = UsBankAccountVerificationSearch.new
        search.account_holder_name.is "v_account_holder_name"

        expect(search.to_hash).to eq({:account_holder_name => {:is => "v_account_holder_name"}})
      end
    end

    context "created_at" do
      it "is a range node" do
        search = UsBankAccountVerificationSearch.new
        expect(search.created_at).to be_kind_of(Braintree::AdvancedSearch::RangeNode)
      end
    end

    context "account number" do
      it "uses ends_with" do
        search = UsBankAccountVerificationSearch.new
        search.account_number.ends_with "1234"

        expect(search.to_hash).to eq({:account_number => {:ends_with => "1234"}})
      end
    end
  end
end
