require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe Braintree::Transaction::PaymentReceipt do
  describe "inspect" do
    it "assigns all fields" do
      details = Braintree::Transaction::PaymentReceipt.new(
        :account_balance => "2.00",
        :amount => "10.00",
        :card_last_4 => "1111",
        :card_present_data => {
            :application_cryptogram => "application-cryptogram",
            :application_identifier => "application-id",
            :application_interchange_profile => "application-interchange",
            :application_name => "application-name",
            :application_transaction_counter => "application-transaction-counter",
            :application_usage_control => "application-usage-control",
            :authorization_mode => "Issuer",
            :authorization_response_code => "auth-response-code",
            :card_entry_method => "card-entry-method",
            :card_sequence_number => "card-sequence-number",
            :cardholder_verification_method_results => "cardholder-verification-method-results",
            :cashback_amount => "20.00",
            :cryptogram_information_data => "cryptogram-information-data",
            :issuer_action_code_default => "issuer-action-code-default",
            :issuer_action_code_denial => "issuer-action-code-denial",
            :issuer_action_code_online => "issuer-action-code-online",
            :issuer_authentication_data => "issuer-authentication-data",
            :terminal_country_code => "USA",
            :terminal_transaction_date => "2023-04-03",
            :terminal_transaction_type => "terminal-transaction-type",
            :terminal_verification_result => "terminal-verification-result",
            :unpredictable_number => "unpredictable-number",
        },
        :card_type => "VISA",
        :currency_iso_code => "USD",
        :global_id => "global-id",
        :id => "id",
        :merchant_address => {
            :locality => "Chicago",
            :phone => "7708675309",
            :postal_code => "60652",
            :region => "IL",
            :street_address => "123 Sesame St",
        },
        :merchant_identification_number => "merchant-id-number",
        :merchant_name => "merchant-name",
        :pin_verified => true,
        :processor_authorization_code => "processor-auth-code",
        :processor_response_code => "processor-response-code",
        :processor_response_text => "processor-response-text",
        :terminal_identification_number => "terminal-id",
        :type => "sale",
      )

      expect(details.account_balance).to eq("2.00")
      expect(details.amount).to eq("10.00")
      expect(details.card_last_4).to eq("1111")
      expect(details.card_present_data).to eq({application_cryptogram: "application-cryptogram", application_identifier: "application-id", application_interchange_profile: "application-interchange", application_name: "application-name", application_transaction_counter: "application-transaction-counter", application_usage_control: "application-usage-control", authorization_mode: "Issuer", authorization_response_code: "auth-response-code", card_entry_method: "card-entry-method", card_sequence_number: "card-sequence-number", cardholder_verification_method_results: "cardholder-verification-method-results", cashback_amount: "20.00", cryptogram_information_data: "cryptogram-information-data", issuer_action_code_default: "issuer-action-code-default", issuer_action_code_denial: "issuer-action-code-denial", issuer_action_code_online: "issuer-action-code-online", issuer_authentication_data: "issuer-authentication-data", terminal_country_code: "USA", terminal_transaction_date: "2023-04-03", terminal_transaction_type: "terminal-transaction-type", terminal_verification_result: "terminal-verification-result", unpredictable_number: "unpredictable-number"})
      expect(details.card_type).to eq("VISA")
      expect(details.currency_iso_code).to eq("USD")
      expect(details.global_id).to eq("global-id")
      expect(details.id).to eq("id")
      expect(details.merchant_address).to eq({locality: "Chicago", phone: "7708675309", postal_code: "60652", region: "IL", street_address: "123 Sesame St"})
      expect(details.merchant_identification_number).to eq("merchant-id-number")
      expect(details.merchant_name).to eq("merchant-name")
      expect(details.pin_verified).to be_truthy
      expect(details.processor_authorization_code).to be("processor-auth-code")
      expect(details.processor_response_text).to be("processor-response-text")
      expect(details.terminal_identification_number).to be("terminal-id")
      expect(details.type).to be("sale")
    end
  end
end
