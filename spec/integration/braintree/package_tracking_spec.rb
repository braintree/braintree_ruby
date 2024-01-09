require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Transaction do
    describe "self.package_tracking" do
        it "returns validation error message from gateway api" do
            # Create Transaction
          result = Braintree::Transaction.sale(
            :amount => "100",
            :options => {
              :submit_for_settlement => true
            },
            :paypal_account => {
              :payer_id => "fake-payer-id",
              :payment_id => "fake-payment-id",
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

          # Create Transaction
          result = Braintree::Transaction.sale(
            :amount => "100",
            :options => {
              :submit_for_settlement => true
            },
            :paypal_account => {
              :payer_id => "fake-payer-id",
              :payment_id => "fake-payment-id",
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

          # Find transaction gives both packages
          findTransaction = Braintree::Transaction.find(result.transaction.id)
          expect(findTransaction.packages.length).to eq(2)
        end
    end
end