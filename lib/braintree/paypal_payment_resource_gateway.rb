module Braintree
    class PayPalPaymentResourceGateway
        include BaseModule

        def initialize(gateway)
            @gateway = gateway
            @config = gateway.config
            @config.assert_has_access_token_or_keys
        end

        def update(attributes)
            Util.verify_keys(PayPalPaymentResourceGateway._update_signature, attributes)
            response = @config.http.put("#{@config.base_merchant_path}/paypal/payment_resource", :paypal_payment_resource => attributes)
            if response[:payment_method_nonce]
                SuccessfulResult.new(:payment_method_nonce => PaymentMethodNonce._new(@gateway, response[:payment_method_nonce]))
            elsif response[:api_error_response]
                ErrorResult.new(@gateway, response[:api_error_response])
            else
                raise UnexpectedError, "expected :paypal_payment_resource or :api_error_response"
            end
        end

        def self._update_signature
            [
                :amount,
                {:amount_breakdown => [:discount, :handling, :insurance, :item_total, :shipping, :shipping_discount, :tax_total]},
                :currency_iso_code, :custom_field, :description,
                {:line_items => [:description, :image_url, :kind, :name, :product_code, :quantity, :total_amount, :unit_amount, :unit_tax_amount, :url]},
                :order_id, :payee_email, :payment_method_nonce,
                {:shipping => [:country_name, :country_code_alpha2, :country_code_alpha3, :country_code_numeric, :extended_address, :first_name, {:international_phone => [:country_code, :national_number]},
                :last_name, :locality, :postal_code, :region, :street_address]},
                {:shipping_options => [:amount, :id, :label, :selected, :type]}
            ]
        end
    end
end