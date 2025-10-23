module Braintree
  class TransactionGateway
    include BaseModule

    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
      @config.assert_has_access_token_or_keys
    end

    def create(attributes)
      # NEXT_MAJOR_VERSION remove this check
      if attributes.has_key?(:venmo_sdk_payment_method_code) || attributes.has_key?(:venmo_sdk_session)
        warn "[DEPRECATED] The Venmo SDK integration is Unsupported. Please update your integration to use Pay with Venmo instead."
      end
      # NEXT_MAJOR_VERSION remove this check
      if attributes.has_key?(:three_d_secure_token)
        warn "[DEPRECATED] Passing :three_d_secure_token to create is deprecated. Please use :three_d_secure_authentication_id"
      end
      Util.verify_keys(TransactionGateway._create_signature, attributes)
      _do_create "/transactions", :transaction => attributes
    end

    def cancel_release(transaction_id)
      raise ArgumentError, "transaction_id is invalid" unless transaction_id =~ /\A[0-9a-z]+\z/
      response = @config.http.put("#{@config.base_merchant_path}/transactions/#{transaction_id}/cancel_release")
      _handle_transaction_response(response)
    end

    def cancel_release!(*args)
      return_object_or_raise(:transaction) { cancel_release(*args) }
    end

    def _handle_transaction_response(response)
      if response[:transaction]
        SuccessfulResult.new(:transaction => Transaction._new(@gateway, response[:transaction]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise UnexpectedError, "expected :transaction or :response"
      end
    end

    def clone_transaction(transaction_id, attributes)
      Util.verify_keys(TransactionGateway._clone_signature, attributes)
      _do_create "/transactions/#{transaction_id}/clone", :transaction_clone => attributes
    end

    def clone_transaction!(*args)
      return_object_or_raise(:transaction) { clone_transaction(*args) }
    end

    def credit(attributes)
      create(attributes.merge(:type => "credit"))
    end

    def credit!(*args)
      return_object_or_raise(:transaction) { credit(*args) }
    end

    def find(id)
      raise ArgumentError, "id can not be empty" if id.nil? || id.strip.to_s == ""
      response = @config.http.get("#{@config.base_merchant_path}/transactions/#{id}")
      Transaction._new(@gateway, response[:transaction])
    rescue NotFoundError
      raise NotFoundError, "transaction with id #{id.inspect} not found"
    end

    def refund(transaction_id, amount_or_options = nil)
      options = if amount_or_options.is_a?(Hash)
                  amount_or_options
                else
                  {:amount => amount_or_options}
                end

      Util.verify_keys(TransactionGateway._refund_signature, options)
      response = @config.http.post("#{@config.base_merchant_path}/transactions/#{transaction_id}/refund", :transaction => options)
      _handle_transaction_response(response)
    end

    def refund!(*args)
      return_object_or_raise(:transaction) { refund(*args) }
    end

    def retry_subscription_charge(subscription_id, amount=nil, submit_for_settlement=false)
      attributes = {
        :amount => amount,
        :subscription_id => subscription_id,
        :type => Transaction::Type::Sale,
        :options => {
          :submit_for_settlement => submit_for_settlement
        }
      }
      _do_create "/transactions", :transaction => attributes
    end

    def sale(attributes)
      create(attributes.merge(:type => "sale"))
    end

    def sale!(*args)
      return_object_or_raise(:transaction) { sale(*args) }
    end

    def package_tracking(transaction_id, package_tracking_request)
      raise ArgumentError, "transaction_id is invalid" unless transaction_id =~ /\A[0-9a-z]+\z/
      Util.verify_keys(TransactionGateway._package_tracking_request_signature, package_tracking_request)
      _do_create "/transactions/#{transaction_id}/shipments", :shipment => package_tracking_request
    end

    def package_tracking!(*args)
      return_object_or_raise(:transaction) { package_tracking(*args) }
    end

    def search(&block)
      search = TransactionSearch.new
      block.call(search) if block

      response = @config.http.post("#{@config.base_merchant_path}/transactions/advanced_search_ids", {:search => search.to_hash})

      if response.has_key?(:search_results)
        ResourceCollection.new(response) { |ids| _fetch_transactions(search, ids) }
      else
        raise UnexpectedError, "expected :search_results"
      end
    end

    def submit_for_settlement(transaction_id, amount = nil, options = {})
      raise ArgumentError, "transaction_id is invalid" unless transaction_id =~ /\A[0-9a-z]+\z/
      Util.verify_keys(TransactionGateway._submit_for_settlement_signature, options)
      transaction_params = {:amount => amount}.merge(options)
      response = @config.http.put("#{@config.base_merchant_path}/transactions/#{transaction_id}/submit_for_settlement", :transaction => transaction_params)
      _handle_transaction_response(response)
    end

    def submit_for_settlement!(*args)
      return_object_or_raise(:transaction) { submit_for_settlement(*args) }
    end

    def adjust_authorization(transaction_id, amount)
      raise ArgumentError, "transaction_id is invalid" unless transaction_id =~ /\A[0-9a-z]+\z/
      Util.verify_keys(TransactionGateway._adjust_authorization_signature, {})
      transaction_params = {:amount => amount}
      response = @config.http.put("#{@config.base_merchant_path}/transactions/#{transaction_id}/adjust_authorization", :transaction => transaction_params)
      _handle_transaction_response(response)
    end

    def adjust_authorization!(*args)
      return_object_or_raise(:transaction) { adjust_authorization(*args) }
    end

    def update_details(transaction_id, options = {})
      raise ArgumentError, "transaction_id is invalid" unless transaction_id =~ /\A[0-9a-z]+\z/
      Util.verify_keys(TransactionGateway._update_details_signature, options)
      response = @config.http.put("#{@config.base_merchant_path}/transactions/#{transaction_id}/update_details", :transaction => options)
      _handle_transaction_response(response)
    end

    def submit_for_partial_settlement(authorized_transaction_id, amount = nil, options = {})
      raise ArgumentError, "authorized_transaction_id is invalid" unless authorized_transaction_id =~ /\A[0-9a-z]+\z/
      Util.verify_keys(TransactionGateway._submit_for_partial_settlement_signature, options)
      transaction_params = {:amount => amount}.merge(options)
      response = @config.http.post("#{@config.base_merchant_path}/transactions/#{authorized_transaction_id}/submit_for_partial_settlement", :transaction => transaction_params)
      _handle_transaction_response(response)
    end

    def submit_for_partial_settlement!(*args)
      return_object_or_raise(:transaction) { submit_for_partial_settlement(*args) }
    end

    def void(transaction_id)
      response = @config.http.put("#{@config.base_merchant_path}/transactions/#{transaction_id}/void")
      _handle_transaction_response(response)
    end

    def void!(*args)
      return_object_or_raise(:transaction) { void(*args) }
    end

    def self._package_tracking_request_signature
      [
        :carrier,
        {:line_items => [:commodity_code, :description, :discount_amount, :image_url, :kind, :name, :product_code, :quantity, :tax_amount, :total_amount, :unit_amount, :unit_of_measure, :unit_tax_amount, :upc_code, :upc_type, :url]},
        :notify_payer, :tracking_number,
      ]
    end

    def self._clone_signature
      [:amount, :channel, {:options => [:submit_for_settlement]}]
    end

    # NEXT_MAJOR_VERSION Remove venmo_sdk_payment_method_code, venmo_sdk_session, and three_d_secure_token
    # The old venmo SDK class has been deprecated
    # three_d_secure_token has been deprecated in favor of three_d_secure_authentication_id
    def self._create_signature
      [
        :amount, :billing_address_id, :channel, :currency_iso_code, :customer_id, :device_data,
        :discount_amount, :exchange_rate_quote_id, :foreign_retailer,
        :merchant_account_id, :order_id, :payment_method_nonce, :payment_method_token, :processing_merchant_category_code,
        :product_sku, :purchase_order_number, :service_fee_amount, :shared_billing_address_id,
        :shared_customer_id, :shared_payment_method_nonce, :shared_payment_method_token,
        :shared_shipping_address_id, :shipping_address_id, :shipping_amount, :shipping_tax_amount,
        :ships_from_postal_code, :tax_amount, :tax_exempt, :three_d_secure_authentication_id,:three_d_secure_token, #Deprecated
        :transaction_source, :type, :venmo_sdk_payment_method_code, # Deprecated
        :sca_exemption,
        {:apple_pay_card => [:number, :cardholder_name, :cryptogram, :expiration_month, :expiration_year, :eci_indicator]},
        {
          :billing => AddressGateway._shared_signature
        },
        {:credit_card => [:token, :cardholder_name, :cvv, :expiration_date, :expiration_month, :expiration_year, :number, {:payment_reader_card_details => [:encrypted_card_data, :key_serial_number]}, {:network_tokenization_attributes => [:cryptogram, :ecommerce_indicator, :token_requestor_id]}]},
        {:customer => [:id, :company, :email, :fax, :first_name, :last_name, :phone, :website]},
        {:custom_fields => :_any_key_},
        {:descriptor => [:name, :phone, :url]},
        {:external_vault => [
          :status,
          :previous_network_transaction_id,
        ]},
        {:google_pay_card => [:number, :cryptogram, :google_transaction_id, :expiration_month, :expiration_year, :source_card_type, :source_card_last_four, :eci_indicator]},
        {:industry => [
          :industry_type,
          {:data => [
            :country_code, :date_of_birth, :folio_number, :check_in_date, :check_out_date, :travel_package, :lodging_check_in_date, :lodging_check_out_date, :departure_date, :lodging_name, :room_rate, :room_tax,
            :passenger_first_name, :passenger_last_name, :passenger_middle_initial, :passenger_title, :issued_date, :travel_agency_name, :travel_agency_code, :ticket_number,
            :issuing_carrier_code, :customer_code, :fare_amount, :fee_amount, :tax_amount, :restricted_ticket, :no_show, :advanced_deposit, :fire_safe, :property_phone, :ticket_issuer_address, :arrival_date,
            {:legs => [
              :conjunction_ticket, :exchange_ticket, :coupon_number, :service_class, :carrier_code, :fare_basis_code, :flight_number, :departure_date, :departure_airport_code, :departure_time,
              :arrival_airport_code, :arrival_time, :stopover_permitted, :fare_amount, :fee_amount, :tax_amount, :endorsement_or_restrictions,
            ]},
            {:additional_charges => [
              :kind, :amount,
            ]},
          ]},
        ]},
        {:installments => [:count]},
        {:line_items => [:commodity_code, :description, :discount_amount, :image_url, :kind, :name, :product_code, :quantity, :tax_amount, :total_amount, :unit_amount, :unit_of_measure, :unit_tax_amount, :upc_code, :upc_type, :url]},
        {:options => [
          :add_billing_address_to_payment_method,
          {:amex_rewards => [:request_id, :points, :currency_amount, :currency_iso_code]},
          {:credit_card => [:account_type, :process_debit_as_credit]},
          :hold_in_escrow,
          :payee_id,
          :payee_email,
          {:paypal => [:custom_field, :description, :payee_id, :payee_email, :recipient_email,  {:recipient_phone => [:country_code, :national_number]}, {:supplementary_data => :_any_key_}]},
          {:processing_overrides => [:customer_email, :customer_first_name, :customer_last_name, :customer_tax_identifier]},
          :skip_advanced_fraud_checking,
          :skip_avs,
          :skip_cvv,
          :store_in_vault,
          :store_in_vault_on_success,
          :store_shipping_address_in_vault,
          :submit_for_settlement,
          {:three_d_secure => [:required]},
          {:venmo => [:profile_id]},
          :venmo_sdk_session, # Deprecated
        ]
        },
        {:paypal_account => [:email, :token, :paypal_data, :payee_id, :payee_email, :payer_id, :payment_id]},
        {:payment_facilitator => [
          :payment_facilitator_id,
          {:sub_merchant => [:reference_number, :tax_id, :legal_name,
            {:address => [ :street_address, :locality, :region, :country_code_alpha2, :postal_code,
              {:international_phone => [:country_code, :national_number
              ]}
            ]}
          ]}
        ]},
        {:risk_data => [:customer_browser, :customer_device_id, :customer_ip, :customer_location_zip, :customer_tenure]},
        {
          :shipping => AddressGateway._shared_signature + [:shipping_method],
        },
        {
          :three_d_secure_pass_thru => [
            :eci_flag,
            :cavv,
            :xid,
            :three_d_secure_version,
            :authentication_response,
            :directory_response,
            :cavv_algorithm,
            :ds_transaction_id,
          ]
        },
        {
          :transfer => [
            :type,
            {
              :sender => [
                :first_name,
                :last_name,
                :account_reference_number,
                :tax_id,
                {:address => AddressGateway._address_attributes}
              ]
            },
            {
              :receiver => [
                :first_name,
                :last_name,
                :account_reference_number,
                :tax_id,
                {:address => AddressGateway._address_attributes}
              ]
            },
          ]
        },
        {
          :us_bank_account => [
            :ach_mandate_text,
            :ach_mandate_accepted_at,
          ]
        },
      ]
    end

    def self._submit_for_settlement_signature
      [
        :order_id,
        {:descriptor => [:name, :phone, :url]},
        {:industry => [
          :industry_type,
          {:data => [
            :country_code, :date_of_birth, :folio_number, :check_in_date, :check_out_date, :travel_package, :lodging_check_in_date, :lodging_check_out_date, :departure_date, :lodging_name, :room_rate, :room_tax,
            :passenger_first_name, :passenger_last_name, :passenger_middle_initial, :passenger_title, :issued_date, :travel_agency_name, :travel_agency_code, :ticket_number,
            :issuing_carrier_code, :customer_code, :fare_amount, :fee_amount, :tax_amount, :restricted_ticket, :no_show, :advanced_deposit, :fire_safe, :property_phone, :ticket_issuer_address, :arrival_date,
            {:legs => [
              :conjunction_ticket, :exchange_ticket, :coupon_number, :service_class, :carrier_code, :fare_basis_code, :flight_number, :departure_date, :departure_airport_code, :departure_time,
              :arrival_airport_code, :arrival_time, :stopover_permitted, :fare_amount, :fee_amount, :tax_amount, :endorsement_or_restrictions,
            ]},
            {:additional_charges => [
              :kind, :amount,
            ]},
          ]},
        ]},
        :purchase_order_number,
        :tax_amount,
        :tax_exempt,
        :discount_amount,
        :shipping_amount,
        :shipping_tax_amount,
        :ships_from_postal_code,
        :line_items => [:commodity_code, :description, :discount_amount, :image_url, :kind, :name, :product_code, :quantity, :tax_amount, :total_amount, :unit_amount, :unit_of_measure, :unit_tax_amount, :upc_code, :upc_type, :url],
      ]
    end

    def self._submit_for_partial_settlement_signature
      _submit_for_settlement_signature + [
        :final_capture
      ]
    end

    def self._adjust_authorization_signature
      [
        :amount
      ]
    end

    def self._update_details_signature
      [
        :amount,
        :order_id,
        {:descriptor => [:name, :phone, :url]},
      ]
    end

    def self._refund_signature
      [
        :amount,
        :merchant_account_id,
        :order_id,
      ]
    end

    def _do_create(path, params=nil)
      if !params.nil?
        params = Util.replace_key(params, :google_pay_card, :android_pay_card)
      end
      response = @config.http.post("#{@config.base_merchant_path}#{path}", params)
      _handle_transaction_response(response)
    end

    def _fetch_transactions(search, ids)
      search.ids.in ids
      response = @config.http.post("#{@config.base_merchant_path}/transactions/advanced_search", {:search => search.to_hash})
      attributes = response[:credit_card_transactions]
      Util.extract_attribute_as_array(attributes, :transaction).map { |attrs| Transaction._new(@gateway, attrs) }
    end
  end
end
