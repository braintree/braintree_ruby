require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::PayPalPaymentResource do

  describe "#update" do
    it "successfully updates a paypal payment request" do
        paypal_payment_resource_request = {
                :amount => 55.00,
                :amount_breakdown => {
                    :discount => 15_00,
                    :handling => 0,
                    :insurance => 5_00,
                    :item_total => 45_00,
                    :shipping => 10_00,
                    :shipping_discount => 0,
                    :tax_total => 10_00
                },
                :currency_iso_code => "USD",
                :description => "This is a test",
                :custom_field => "0437",
                :line_items => [{
                    :description => "Shoes",
                    :image_url => "https://example.com/products/23434/pic.png",
                    :kind => "debit",
                    :name => "Name #1",
                    :product_code => "23434",
                    :quantity => 1_00,
                    :total_amount => 45_00,
                    :unit_amount => 45_00,
                    :unit_tax_amount => 10_00,
                    :url =>  "https://example.com/products/23434",
                    }],
                :order_id => "order-123456789",
                :payee_email => "bt_buyer_us@paypal.com",
                :payment_method_nonce => "1234",
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
                    :amount => "10.00",
                    :id => "option1",
                    :label => "fast",
                    :selected => true,
                    :type =>  "SHIPPING"
                }]
    }

        unknown_response = {:payment_method_nonce => {}}
        http_instance = double(:put => unknown_response)
        allow(Braintree::Http).to receive(:new).and_return(http_instance)
        result = Braintree::PayPalPaymentResource.update(paypal_payment_resource_request)
        expect(result).to be_success
    end
    it "should match the update signature" do
        expect(Braintree::PayPalPaymentResourceGateway._update_signature).to match([
            :amount,
            {:amount_breakdown => [
                :discount,
                :handling,
                :insurance,
                :item_total,
                :shipping,
                :shipping_discount,
                :tax_total
            ]},
            :currency_iso_code,
            :custom_field,
            :description,
            {:line_items => [
                :description,
                :image_url,
                :kind,
                :name,
                :product_code,
                :quantity,
                :total_amount,
                :unit_amount,
                :unit_tax_amount,
                :url,
                ]},
            :order_id,
            :payee_email,
            :payment_method_nonce,
            {:shipping => [
                :country_name,
                :country_code_alpha2,
                :country_code_alpha3,
                :country_code_numeric,
                :extended_address,
                :first_name,
                {:international_phone => [
                    :country_code,
                    :national_number]},
                :last_name,
                :locality,
                :postal_code,
                :region,
                :street_address,
            ]},
            {:shipping_options => [
                :amount,
                :id,
                :label,
                :selected,
                :type
            ]},
        ],
        )
    end
  end
end