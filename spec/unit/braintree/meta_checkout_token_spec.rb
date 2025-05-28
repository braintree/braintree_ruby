require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::MetaCheckoutToken do
    let(:attributes) do {
        :bin => "abc1234",
        :business => "NO",
        :container_id => "a-container-id",
        :card_type => "Visa",
        :cardholder_name => "Meta Checkout Card CardHolder",
        :commercial => "NO",
        :consumer => "NO",
        :corporate => "NO",
        :country_of_issuance => "US",
        :created_at => "2023-05-05T21:28:37Z",
        :debit => "NO",
        :durbin_regulated => "NO",
        :expiration_month => "05",
        :expiration_year => "2024",
        :healthcare => "NO",
        :last_4 => "1234",
        :payroll => "NO",
        :prepaid => "NO",
        :prepaid_reloadable => "NO",
        :purchase => "NO",
        :token => "token1",
        :unique_number_identifier => "abc1234",
        :updated_at => "2023-05-05T21:28:37Z",
        :cryptogram => "AlhlvxmN2ZKuAAESNFZ4GoABFA==",
        :ecommerce_indicator => "07"
    }
    end

    describe "unit tests" do
        it "initializes with the correct attributes" do
            card = Braintree::MetaCheckoutToken._new(:gateway, attributes)

            card.bin.should == "abc1234"
            card.container_id.should == "a-container-id"
            card.card_type.should == "Visa"
            card.cardholder_name.should == "Meta Checkout Card CardHolder"
            card.commercial == "NO"
            card.country_of_issuance == "US"
            card.created_at == "2023-05-05T21:28:37Z"
            card.updated_at == "2023-05-05T21:28:37Z"
            card.debit == "NO"
            card.payroll == "NO"
            card.prepaid == "NO"
            card.prepaid_reloadable == "NO"
            card.healthcare == "NO"
            card.token == "token1"
            card.unique_number_identifier == "abc1234"
            card.expiration_month.should == "05"
            card.expiration_year.should == "2024"
            card.last_4.should == "1234"
            card.cryptogram == "AlhlvxmN2ZKuAAESNFZ4GoABFA=="
            card.ecommerce_indicator == "07"
        end

        it "sets expiration date correctly" do
            card = Braintree::MetaCheckoutToken._new(:gateway, attributes)
            card.expiration_date.should == "05/2024"
        end

        it "masks the card number correctly" do
            card = Braintree::MetaCheckoutToken._new(:gateway, attributes)
            card.masked_number.should == "abc1234******1234"
        end
    end
end
