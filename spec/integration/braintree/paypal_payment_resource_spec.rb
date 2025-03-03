require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::PayPalPaymentResource do

    describe "self.update" do
        it "successfully updates a payment resource" do
            nonce = nonce_for_paypal_account(
                :intent => "order",
                :payment_token => "fake-paypal-payment-token",
                :payer_id => "fake-paypal-payer-id",
              )

            result = Braintree::PayPalPaymentResource.update(
                    :amount => BigDecimal("55.00"),
                    :amount_breakdown => {
                        :discount => BigDecimal("15.00"),
                        :handling =>  BigDecimal("0.00"),
                        :insurance =>  BigDecimal("5.00"),
                        :item_total =>  BigDecimal("45.00"),
                        :shipping =>  BigDecimal("10.00"),
                        :shipping_discount =>  BigDecimal("0.00"),
                        :tax_total =>  BigDecimal("10.00"),
                    },
                    :currency_iso_code => "USD",
                    :custom_field => "0437",
                    :description => "This is a test",
                    :line_items => [{
                        :description => "Shoes",
                        :image_url => "https://example.com/products/23434/pic.png",
                        :kind => "debit",
                        :name => "Name #1",
                        :product_code => "23434",
                        :quantity => "1",
                        :total_amount =>  BigDecimal("45.00"),
                        :unit_amount =>  BigDecimal("45.00"),
                        :unit_tax_amount =>  BigDecimal("10.00"),
                        :url =>  "https://example.com/products/23434",
                    }],
                    :order_id => "order-123456789",
                    :payee_email => "bt_buyer_us@paypal.com",
                    :payment_method_nonce => nonce,
                    :shipping => {
                        :country_name => "United States",
                        :country_code_alpha2 => "US",
                        :country_code_alpha3 => "USA",
                        :country_code_numeric => "484",
                        :extended_address => "Apt. #1",
                        :first_name => "John",
                        :international_phone => {
                            :country_code => "1",
                            :national_number => "4081111111",
                        },
                        :last_name => "Doe",
                        :locality => "Chicago",
                        :postal_code => "60618",
                        :region => "IL",
                        :street_address => "123 Division Street",
                    },
                    :shipping_options => [{
                        :amount =>  BigDecimal("10.00"),
                        :id => "option1",
                        :label => "fast",
                        :selected => true,
                        :type =>  "SHIPPING"
                    }],
            )

            expect(result.success?).to eq(true)
            expect(result.payment_method_nonce).not_to be_nil
            expect(result.payment_method_nonce.nonce).not_to be_nil
        end

        it "returns validation errors" do
            nonce = nonce_for_paypal_account(
                :intent => "order",
                :payment_token => "fake-paypal-payment-token",
                :payer_id => "fake-paypal-payer-id",
              )

              result = Braintree::PayPalPaymentResource.update(
                :amount => BigDecimal("55.00"),
                :amount_breakdown => {
                    :discount => BigDecimal("15.00"),
                    :handling =>  BigDecimal("0.00"),
                    :insurance =>  BigDecimal("5.00"),
                    :item_total =>  BigDecimal("45.00"),
                    :shipping =>  BigDecimal("10.00"),
                    :shipping_discount =>  BigDecimal("0.00"),
                    :tax_total =>  BigDecimal("10.00"),
                },
                :currency_iso_code => "USD",
                :custom_field => "0437",
                :description => "This is a test",
                :line_items => [{
                    :description => "Shoes",
                    :image_url => "https://example.com/products/23434/pic.png",
                    :kind => "debit",
                    :name => "Name #1",
                    :product_code => "23434",
                    :quantity => "1",
                    :total_amount =>  BigDecimal("45.00"),
                    :unit_amount =>  BigDecimal("45.00"),
                    :unit_tax_amount =>  BigDecimal("10.00"),
                    :url =>  "https://example.com/products/23434",
                }],
                :order_id => "order-123456789",
                :payee_email => "bt_buyer_us@paypal",
                :payment_method_nonce => nonce,
                :shipping => {
                    :country_name => "United States",
                    :country_code_alpha2 => "US",
                    :country_code_alpha3 => "USA",
                    :country_code_numeric => "484",
                    :extended_address => "Apt. #1",
                    :first_name => "John",
                    :international_phone => {
                        :country_code => "1",
                        :national_number => "4081111111",
                    },
                    :last_name => "Doe",
                    :locality => "Chicago",
                    :postal_code => "60618",
                    :region => "IL",
                    :street_address => "123 Division Street",
                },
                :shipping_options => [{
                    :amount =>  BigDecimal("10.00"),
                    :id => "option1",
                    :label => "fast",
                    :selected => true,
                    :type =>  "SHIPPING"
                }],
            )

            expect(result.success?).to eq(false)
            errors = result.errors.for(:paypal_payment_resource)
            expect(errors.on(:payee_email)[0].code).to eq(Braintree::ErrorCodes::PayPalPaymentResource::InvalidEmail)
        end
    end
end
