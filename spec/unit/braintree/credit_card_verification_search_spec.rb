require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Braintree
  describe CreditCardVerificationSearch do

    context "card_type" do
      it "allows All card types" do
        search = CreditCardVerificationSearch.new

        expect do
          search.credit_card_card_type.in(
            *Braintree::CreditCard::CardType::All,
          )
        end.not_to raise_error
      end
    end

    context "id" do
      it "is" do
        search = CreditCardVerificationSearch.new
        search.id.is "v_id"

        expect(search.to_hash).to eq({:id => {:is => "v_id"}})
      end
    end

    context "ids" do
      it "correctly builds a hash with ids" do
        search = CreditCardVerificationSearch.new
        search.ids.in("id1","id2")

        expect(search.to_hash).to eq({:ids => ["id1", "id2"]})
      end
    end

    context "credit_card_cardholder_name" do
      it "is" do
        search = CreditCardVerificationSearch.new
        search.credit_card_cardholder_name.is "v_cardholder_name"

        expect(search.to_hash).to eq({:credit_card_cardholder_name => {:is => "v_cardholder_name"}})
      end
    end

    context "credit_card_expiration_date" do
      it "is_not" do
        search = CreditCardVerificationSearch.new
        search.credit_card_expiration_date.is_not "v_credit_card_expiration_date"

        expect(search.to_hash).to eq({:credit_card_expiration_date => {:is_not => "v_credit_card_expiration_date"}})
      end
    end

    context "credit_card_number" do
      it "starts with" do
        search = CreditCardVerificationSearch.new

        search.credit_card_number.starts_with "v_credit_card_bin"

        expect(search.to_hash).to eq({:credit_card_number => {:starts_with => "v_credit_card_bin"}})
      end

      it "ends with" do
        search = CreditCardVerificationSearch.new

        search.credit_card_number.ends_with "v_credit_card_last_4"

        expect(search.to_hash).to eq({:credit_card_number => {:ends_with => "v_credit_card_last_4"}})
      end
    end

    context "created_at" do
      it "is a range node" do
        search = CreditCardVerificationSearch.new
        expect(search.created_at).to be_kind_of(Braintree::AdvancedSearch::RangeNode)
      end
    end
  end
end
