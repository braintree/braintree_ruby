require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe "Transaction ACH Mandate" do
  describe "transaction request handling" do
    let(:gateway) { Braintree::Gateway.new(:environment => :sandbox, :merchant_id => "test", :public_key => "test", :private_key => "test") }
    let(:transaction_gateway) { gateway.transaction }

    it "processes us_bank_account ACH mandate fields" do
      mandate_time = Time.now

      # Mock the HTTP response for transaction creation
      allow(gateway.config.http).to receive(:post).and_return({
        :transaction => {
          :id => "test_transaction_id",
          :amount => "100.00",
          :status => "authorized",
          :us_bank_account => {
            :token => "test_token",
            :ach_mandate => {
              :text => "I authorize this ACH debit",
              :accepted_at => mandate_time.iso8601
            }
          }
        }
      })

      transaction_attributes = {
        :amount => "100.00",
        :payment_method_token => "test_token",
        :us_bank_account => {
          :ach_mandate_text => "I authorize this ACH debit",
          :ach_mandate_accepted_at => mandate_time
        }
      }

      # This should not raise an error due to signature validation
      expect {
        Braintree::Util.verify_keys(Braintree::TransactionGateway._create_signature, transaction_attributes)
      }.not_to raise_error
    end

    it "allows ACH mandate text only" do
      transaction_attributes = {
        :amount => "50.00",
        :payment_method_token => "test_token",
        :us_bank_account => {
          :ach_mandate_text => "I authorize this ACH debit"
        }
      }

      expect {
        Braintree::Util.verify_keys(Braintree::TransactionGateway._create_signature, transaction_attributes)
      }.not_to raise_error
    end

    it "allows ACH mandate accepted_at only" do
      transaction_attributes = {
        :amount => "50.00",
        :payment_method_token => "test_token",
        :us_bank_account => {
          :ach_mandate_accepted_at => Time.now
        }
      }

      expect {
        Braintree::Util.verify_keys(Braintree::TransactionGateway._create_signature, transaction_attributes)
      }.not_to raise_error
    end

    it "allows empty us_bank_account hash" do
      transaction_attributes = {
        :amount => "50.00",
        :payment_method_token => "test_token",
        :us_bank_account => {}
      }

      expect {
        Braintree::Util.verify_keys(Braintree::TransactionGateway._create_signature, transaction_attributes)
      }.not_to raise_error
    end
  end
end