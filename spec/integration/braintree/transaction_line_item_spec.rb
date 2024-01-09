require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::TransactionLineItem do
  describe "self.find_all" do
    it "returns line_items for the specified transaction" do
      result = Braintree::Transaction.create(
        :type => "sale",
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
        :line_items => [
          {
            :quantity => "1.0232",
            :name => "Name #1",
            :kind => "debit",
            :unit_amount => "45.1232",
            :total_amount => "45.15",
            :upc_code => "11223344556677889",
            :upc_type => "UPC-A",
            :image_url => "https://google.com/image.png",
          },
        ],
      )
      expect(result.success?).to eq(true)
      transaction = result.transaction

      line_items = Braintree::TransactionLineItem.find_all(transaction.id)

      line_item = line_items[0]
      expect(line_item.quantity).to eq(BigDecimal("1.0232"))
      expect(line_item.name).to eq("Name #1")
      expect(line_item.kind).to eq("debit")
      expect(line_item.unit_amount).to eq(BigDecimal("45.1232"))
      expect(line_item.total_amount).to eq(BigDecimal("45.15"))
      expect(line_item.upc_type).to eq("UPC-A")
      expect(line_item.upc_code).to eq("11223344556677889")
      expect(line_item.image_url).to eq("https://google.com/image.png")
    end
  end
end

