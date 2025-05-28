require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::Transaction::CreditCardDetails do
  describe "expiration_date" do
    it "concats expiration_month and expiration_year" do
      details = Braintree::Transaction::CreditCardDetails.new(
        :expiration_month => "08",
        :expiration_year => "2009",
      )
      expect(details.expiration_date).to eq("08/2009")
    end
  end

  describe "inspect" do
    it "inspects" do
      details = Braintree::Transaction::CreditCardDetails.new(
        :bin => "123456",
        :business => "No",
        :card_type => "Visa",
        :cardholder_name => "The Cardholder",
        :expiration_month => "05",
        :expiration_year => "2012",
        :last_4 => "6789",
        :token => "token",
        :customer_location => "US",
        :healthcare => "No",
        :prepaid => "Yes",
        :prepaid_reloadable => "Yes",
        :durbin_regulated => "No",
        :debit => "Yes",
        :commercial => "Unknown",
        :consumer => "Unknown",
        :corporate => "Unknown",
        :payroll => "Unknown",
        :purchase => "Unknown",
        :product_id => "Unknown",
        :country_of_issuance => "Lilliput",
        :issuing_bank => "Gulliver Bank",
        :image_url => "example.com/visa.png",
        :unique_number_identifier => "abc123",
      )
      expect(details.inspect).to eq(%(#<token: "token", bin: "123456", business: "No", last_4: "6789", card_type: "Visa", commercial: "Unknown", consumer: "Unknown", corporate: "Unknown", country_of_issuance: "Lilliput", customer_location: "US", debit: "Yes", durbin_regulated: "No", expiration_date: "05/2012", healthcare: "No", image_url: "example.com/visa.png", issuing_bank: "Gulliver Bank", payroll: "Unknown", prepaid: "Yes", prepaid_reloadable: "Yes", product_id: "Unknown", purchase: "Unknown", cardholder_name: "The Cardholder", unique_number_identifier: "abc123">))
    end
  end

  describe "masked_number" do
    it "concatenates the bin, some *'s, and the last_4" do
      details = Braintree::Transaction::CreditCardDetails.new(
        :bin => "510510", :last_4 => "5100",
      )
      expect(details.masked_number).to eq("510510******5100")
    end
  end

  describe "is_network_tokenized" do
    it "returns true if is_network_tokenized is true" do
      details = Braintree::Transaction::CreditCardDetails.new(
        :is_network_tokenized => true,
      )
      expect(details.is_network_tokenized?).to eq(true)
    end

    it "returns false if is_network_tokenized is false" do
      details = Braintree::Transaction::CreditCardDetails.new(
        :is_network_tokenized => false,
      )
      expect(details.is_network_tokenized?).to eq(false)
    end
  end
end
