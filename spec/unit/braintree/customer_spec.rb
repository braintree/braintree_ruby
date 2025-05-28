require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Customer do
  describe "inspect" do
    it "includes the id first" do
      output = Braintree::Customer._new(:gateway, {:first_name => "Dan", :id => "1234"}).inspect
      expect(output).to include("#<Braintree::Customer id: \"1234\",")
    end

    it "includes all customer attributes" do
      customer = Braintree::Customer._new(
        :gateway,
        :company => "Company",
        :email => "e@mail.com",
        :fax => "483-438-5821",
        :first_name => "Patrick",
        :last_name => "Smith",
        :phone => "802-483-5932",
        :international_phone => {:country_code => "1", :national_number => "3121234567"},
        :website => "patrick.smith.com",
        :created_at => Time.now,
        :updated_at => Time.now,
      )
      output = customer.inspect
      expect(output).to include(%q(company: "Company"))
      expect(output).to include(%q(email: "e@mail.com"))
      expect(output).to include(%q(fax: "483-438-5821"))
      expect(output).to include(%q(first_name: "Patrick"))
      expect(output).to include(%q(last_name: "Smith"))
      expect(output).to include(%q(phone: "802-483-5932"))
      expect(output).to include(%q(international_phone: {:country_code=>"1", :national_number=>"3121234567"}))
      expect(output).to include(%q(website: "patrick.smith.com"))
      expect(output).to include(%q(addresses: []))
      expect(output).to include(%q(credit_cards: []))
      expect(output).to include(%q(paypal_accounts: []))
      expect(output).to include(%q(tax_identifiers: []))
      expect(output).to include(%Q(created_at: #{customer.created_at.inspect}))
      expect(output).to include(%Q(updated_at: #{customer.updated_at.inspect}))
    end
  end

  describe "self.create" do
    it "raises an exception if hash includes an invalid key" do
      expect do
        Braintree::Customer.create(:first_name => "Joe", :invalid_key => "foo")
      end.to raise_error(ArgumentError, "invalid keys: invalid_key")
    end
  end

  describe "self.find" do
    it "raises an exception if the id is blank" do
      expect do
        Braintree::Customer.find("  ")
      end.to raise_error(ArgumentError)
    end

    it "raises an exception if the id is nil" do
      expect do
        Braintree::Customer.find(nil)
      end.to raise_error(ArgumentError)
    end

    it "does not raise an exception if the id is a fixnum" do
      allow(Braintree::Http).to receive(:new).and_return double.as_null_object
      expect do
        Braintree::Customer.find(8675309)
      end.to_not raise_error
    end
  end

  describe "self.update" do
    it "raises an exception if hash includes an invalid key" do
      expect do
        Braintree::Customer.update("customer_id", :first_name => "Joe", :invalid_key => "foo")
      end.to raise_error(ArgumentError, "invalid keys: invalid_key")
    end
  end

  describe "self.create_signature" do
    it "should be what we expect" do
      expect(Braintree::CustomerGateway._create_signature).to match([
        :company,
        :email,
        :fax,
        :first_name,
        :id,
        {:international_phone=>[:country_code, :national_number]},
        :last_name,
        :phone,
        :website,
        :device_data,
        :payment_method_nonce,
        {:risk_data => [:customer_browser, :customer_ip]},
        {:credit_card => [
          :billing_address_id,
          :cardholder_name,
          :cvv,
          :expiration_date,
          :expiration_month,
          :expiration_year,
          :number,
          :token,
          :venmo_sdk_payment_method_code, # NEXT_MAJOR_VERSION Remove this attribute
          :device_data,
          :payment_method_nonce,
          {:external_vault=>[:network_transaction_id]},
          {:options => match_array([:make_default, :skip_advanced_fraud_checking, :verification_merchant_account_id, :verify_card, :verification_amount, :venmo_sdk_session, # NEXT_MAJOR_VERSION Remove this attribute
            :account_information_inquiry, :fail_on_duplicate_payment_method, :verification_account_type, :verification_currency_iso_code])},
          {:billing_address => [
            :company,
            :country_code_alpha2,
            :country_code_alpha3,
            :country_code_numeric,
            :country_name,
            :extended_address,
            :first_name,
            {:international_phone=>[:country_code, :national_number]},
            :last_name,
            :locality,
            :phone_number,
            :postal_code,
            :region,
            :street_address
          ]},
          {:three_d_secure_pass_thru => [
            :eci_flag,
            :cavv,
            :xid,
            :three_d_secure_version,
            :authentication_response,
            :directory_response,
            :cavv_algorithm,
            :ds_transaction_id,
          ]},
        ]},
        {:paypal_account => [
          :email,
          :token,
          :billing_agreement_id,
          {:options => [:make_default]},
        ]},
        {:tax_identifiers => [
          :country_code,
          :identifier
        ]},
        {:options =>
          [:paypal => [
            :payee_email,
            :order_id,
            :custom_field,
            :description,
            :amount,
            {:shipping => [
              :company,
              :country_code_alpha2,
              :country_code_alpha3,
              :country_code_numeric,
              :country_name,
              :extended_address,
              :first_name,
              {:international_phone=>[:country_code, :national_number]},
              :last_name,
              :locality,
              :phone_number,
              :postal_code,
              :region,
              :street_address,
            ]}
          ]]
        },
        {:custom_fields => :_any_key_}
      ])
    end
  end

  describe "self.update_signature" do
    it "should be what we expect" do
      expect(Braintree::CustomerGateway._update_signature).to match([
        :company,
        :email,
        :fax,
        :first_name,
        :id,
        {:international_phone=>[:country_code, :national_number]},
        :last_name,
        :phone,
        :website,
        :device_data,
        :payment_method_nonce,
        :default_payment_method_token,
        {:credit_card => [
          :billing_address_id,
          :cardholder_name,
          :cvv,
          :expiration_date,
          :expiration_month,
          :expiration_year,
          :number,
          :token,
          :venmo_sdk_payment_method_code, # NEXT_MAJOR_VERSION Remove this attribute
          :device_data,
          :payment_method_nonce,
          {:external_vault=>[:network_transaction_id]},
          {:options => match_array([
            :account_information_inquiry,
            :make_default,
            :skip_advanced_fraud_checking,
            :verification_merchant_account_id,
            :verify_card,
            :verification_amount,
            :venmo_sdk_session, # NEXT_MAJOR_VERSION Remove this attribute
            :fail_on_duplicate_payment_method,
            :fail_on_duplicate_payment_method_for_customer,
            :verification_account_type,
            :verification_currency_iso_code,
            :update_existing_token
          ])},
          {:billing_address => [
            :company,
            :country_code_alpha2,
            :country_code_alpha3,
            :country_code_numeric,
            :country_name,
            :extended_address,
            :first_name,
            {:international_phone=>[:country_code, :national_number]},
            :last_name,
            :locality,
            :phone_number,
            :postal_code,
            :region,
            :street_address,
            {:options => [:update_existing]}
          ]},
          {:three_d_secure_pass_thru => [
            :eci_flag,
            :cavv,
            :xid,
            :three_d_secure_version,
            :authentication_response,
            :directory_response,
            :cavv_algorithm,
            :ds_transaction_id,
          ]},
        ]},
        {:tax_identifiers => [
          :country_code,
          :identifier
        ]},
        {:options =>
          [:paypal => [
            :payee_email,
            :order_id,
            :custom_field,
            :description,
            :amount,
            {:shipping => [
              :company,
              :country_code_alpha2,
              :country_code_alpha3,
              :country_code_numeric,
              :country_name,
              :extended_address,
              :first_name,
              {:international_phone=>[:country_code, :national_number]},
              :last_name,
              :locality,
              :phone_number,
              :postal_code,
              :region,
              :street_address,
            ]}
          ]]
        },
        {:custom_fields => :_any_key_}
      ])
    end
  end

  describe "==" do
    it "returns true when given a customer with the same id" do
      first = Braintree::Customer._new(:gateway, :id => 123)
      second = Braintree::Customer._new(:gateway, :id => 123)

      expect(first).to eq(second)
      expect(second).to eq(first)
    end

    it "returns false when given a customer with a different id" do
      first = Braintree::Customer._new(:gateway, :id => 123)
      second = Braintree::Customer._new(:gateway, :id => 124)

      expect(first).not_to eq(second)
      expect(second).not_to eq(first)
    end

    it "returns false when not given a customer" do
      customer = Braintree::Customer._new(:gateway, :id => 123)
      expect(customer).not_to eq("not a customer")
    end
  end

  describe "initialize" do
    it "converts payment method hashes into payment method objects" do
      customer = Braintree::Customer._new(
        :gateway,
        :credit_cards => [
          {:token => "credit_card_1"},
          {:token => "credit_card_2"}
        ],
        :paypal_accounts => [
          {:token => "paypal_1"},
          {:token => "paypal_2"}
        ],
        :sepa_debit_accounts => [
          {:token => "sepa_debit_1"},
          {:token => "sepa_debit_2"}
        ],
      )

      expect(customer.credit_cards.size).to eq(2)
      expect(customer.credit_cards[0].token).to eq("credit_card_1")
      expect(customer.credit_cards[1].token).to eq("credit_card_2")

      expect(customer.paypal_accounts.size).to eq(2)
      expect(customer.paypal_accounts[0].token).to eq("paypal_1")
      expect(customer.paypal_accounts[1].token).to eq("paypal_2")

      expect(customer.sepa_direct_debit_accounts.size).to eq(2)
      expect(customer.sepa_direct_debit_accounts[0].token).to eq("sepa_debit_1")
      expect(customer.sepa_direct_debit_accounts[1].token).to eq("sepa_debit_2")

      expect(customer.payment_methods.count).to eq(6)
      expect(customer.payment_methods.map(&:token)).to include("credit_card_1")
      expect(customer.payment_methods.map(&:token)).to include("credit_card_2")
      expect(customer.payment_methods.map(&:token)).to include("paypal_1")
      expect(customer.payment_methods.map(&:token)).to include("paypal_2")
      expect(customer.payment_methods.map(&:token)).to include("sepa_debit_1")
      expect(customer.payment_methods.map(&:token)).to include("sepa_debit_2")
    end
  end

  describe "new" do
    it "is protected" do
      expect do
        Braintree::Customer.new
      end.to raise_error(NoMethodError, /protected method .new/)
    end
  end
end
