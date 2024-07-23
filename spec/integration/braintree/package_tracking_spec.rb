require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

# NEXT_MAJOR_VERSION Remove paypal_tracking_id assertions, use paypal_tracker_id going forward
describe Braintree::Transaction do
    describe "self.package_tracking" do
      let(:customer) { Braintree::Customer.create! }
        it "returns validation error message from gateway api" do
          result = Braintree::Transaction.sale(
            :amount => "100",
            :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
            :options => {
              :submit_for_settlement => true
            },
          )

          expect(result.success?).to eq(true)

          # Carrier name is required
          invalidResult = Braintree::Transaction.package_tracking(result.transaction.id, {tracking_number: "tracking_number_1"})
          expect(invalidResult.message).to eq("Carrier name is required.")

           # Tracking number is required
           invalidResult = Braintree::Transaction.package_tracking(result.transaction.id, {carrier: "UPS"})
           expect(invalidResult.message).to eq("Tracking number is required.")
        end

        it "successfully calls gateway API and adds package tracking information" do
          result = Braintree::Transaction.sale(
            :amount => "100",
            :payment_method_nonce => Braintree::Test::Nonce::PayPalOneTimePayment,
            :options => {
              :submit_for_settlement => true
            },
          )

          expect(result.success?).to eq(true)

          # Create First Package with 2 products
          firstPackageResult = Braintree::Transaction.package_tracking(
            result.transaction.id,
            {
              carrier: "UPS",
              notify_payer: true,
              tracking_number: "tracking_number_1",
              line_items: [
                {
                  product_code: "ABC 01",
                  name: "Best Product Ever",
                  quantity: "1",
                  description: "Best Description Ever",
                  upc_code: "51234567890",
                  upc_type: "UPC-A",
                  image_url: "https://example.com/image.png",
                },
                {
                  product_code: "ABC 02",
                  name: "Best Product Ever",
                  quantity: "1",
                  description: "Best Description Ever",
                  upc_code: "51234567891",
                  upc_type: "UPC-A",
                  image_url: "https://example.com/image.png",
                },
              ],
            },
          )

          # First package is shipped by the merchant
          expect(firstPackageResult.success?).to eq(true)
          expect(firstPackageResult.transaction.packages[0].id).not_to be_nil
          expect(firstPackageResult.transaction.packages[0].carrier).to eq("UPS")
          expect(firstPackageResult.transaction.packages[0].tracking_number).to eq("tracking_number_1")
          expect(firstPackageResult.transaction.packages[0].paypal_tracker_id).to be_nil
          expect(firstPackageResult.transaction.packages[0].paypal_tracking_id).to be_nil

          # Create second package with 1 product
          secondPackageResult = Braintree::Transaction.package_tracking(
            result.transaction.id,
            {
              carrier: "FEDEX",
              notify_payer: true,
              tracking_number: "tracking_number_2",
              line_items: [
                {
                  product_code: "ABC 03",
                  name: "Best Product Ever",
                  quantity: "1",
                  description: "Best Description Ever",
                },
              ]
            },
          )

          # Second package is shipped by the merchant
          expect(secondPackageResult.success?).to eq(true)
          expect(secondPackageResult.transaction.packages[1].id).not_to be_nil
          expect(secondPackageResult.transaction.packages[1].carrier).to eq("FEDEX")
          expect(secondPackageResult.transaction.packages[1].tracking_number).to eq("tracking_number_2")
          expect(secondPackageResult.transaction.packages[1].paypal_tracker_id).to be_nil
          expect(secondPackageResult.transaction.packages[1].paypal_tracking_id).to be_nil

          # Find transaction gives both packages
          transaction = Braintree::Transaction.find(result.transaction.id)
          expect(transaction.packages.length).to eq(2)
          expect(transaction.packages[0].id).not_to be_nil
          expect(transaction.packages[0].carrier).to eq("UPS")
          expect(transaction.packages[0].tracking_number).to eq("tracking_number_1")
          #In test environment, since we do not have jobstream setup paypal tracker id is going to be nil, this is just to access we could access it
          expect(transaction.packages[0].paypal_tracker_id).to be_nil
          expect(transaction.packages[0].paypal_tracking_id).to be_nil

          expect(transaction.packages[1].id).not_to be_nil
          expect(transaction.packages[1].carrier).to eq("FEDEX")
          expect(transaction.packages[1].tracking_number).to eq("tracking_number_2")
          expect(transaction.packages[1].paypal_tracker_id).to be_nil
          expect(transaction.packages[1].paypal_tracking_id).to be_nil
        end

        it "retrieves paypal_tracker_id successfully" do
          transaction = Braintree::Transaction.find("package_tracking_tx")
          expect(transaction.packages.length).to eq(2)
          expect(transaction.packages[0].paypal_tracker_id).to eq("paypal_tracker_id_1")
          expect(transaction.packages[0].paypal_tracking_id).to be_nil

          expect(transaction.packages[1].paypal_tracker_id).to eq("paypal_tracker_id_2")
          expect(transaction.packages[1].paypal_tracking_id).to be_nil
        end
    end
end
