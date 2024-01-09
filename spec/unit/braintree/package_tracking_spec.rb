require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe "Package Tracking Unit Tests" do
    describe "creates and validates requests" do
        let(:gateway) do
            config = Braintree::Configuration.new(
              :merchant_id => "merchant_id",
              :public_key => "public_key",
              :private_key => "private_key",
            )
            Braintree::Gateway.new(config)
        end

          it "creates transaction gateway package tracking request signature" do
            expect(Braintree::TransactionGateway._package_tracking_request_signature).to match(
              [
                :carrier,
                {:line_items => [:commodity_code, :description, :discount_amount, :image_url, :kind, :name, :product_code, :quantity, :tax_amount, :total_amount, :unit_amount, :unit_of_measure, :unit_tax_amount, :upc_code, :upc_type, :url]},
                :notify_payer, :tracking_number,
              ],
            )
          end

          it "raises an ArgumentError if transaction_id is an invalid format" do
            expect do
              Braintree::Transaction.package_tracking("invalid-transaction-id", {})
            end.to raise_error(ArgumentError, "transaction_id is invalid")
          end

          it "raises an exception if attributes contain an invalid key" do
            expect do
                Braintree::Transaction.package_tracking("txn123", {:invalid_key => "random", :carrier => "UPS", :tracking_number => "123123"})
            end.to raise_error(ArgumentError, "invalid keys: invalid_key")
          end
    end

    describe "handles response" do
        it "parses the packages response correctly" do
          transaction = Braintree::Transaction._new(
            :gateway,
            :shipments => [
              {:id => "id1", :carrier => "UPS", :tracking_number => "tracking_number_1", :paypal_tracking_id => "pp_tracking_number_1"},
              {:id => "id2", :carrier => "FEDEX", :tracking_number => "tracking_number_2", :paypal_tracking_id => "pp_tracking_number_2"}
            ],
          )
          expect(transaction.packages.size).to eq(2)
          expect(transaction.packages[0].id).to eq("id1")
          expect(transaction.packages[0].carrier).to eq("UPS")
          expect(transaction.packages[0].tracking_number).to eq("tracking_number_1")
          expect(transaction.packages[0].paypal_tracking_id).to eq("pp_tracking_number_1")

          expect(transaction.packages[1].id).to eq("id2")
          expect(transaction.packages[1].carrier).to eq("FEDEX")
          expect(transaction.packages[1].tracking_number).to eq("tracking_number_2")
          expect(transaction.packages[1].paypal_tracking_id).to eq("pp_tracking_number_2")
        end

        it "doesn't blow up if no shipments are present in the transaction response" do
            transaction = Braintree::Transaction._new(
                :gateway,
                :shipments => [],
              )
              expect(transaction.packages.size).to eq(0)
        end

        it "doesn't blow up if shipments tag is not present in the transaction response" do
            transaction = Braintree::Transaction._new(
                :gateway,
                {},
              )
              expect(transaction.packages.size).to eq(0)
        end
    end
end