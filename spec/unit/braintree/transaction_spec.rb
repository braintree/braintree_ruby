require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::Transaction do
  describe "self.clone_transaction" do
    it "raises an exception if hash includes an invalid key" do
      expect do
        Braintree::Transaction.clone_transaction("an_id", :amount => "10.00", :invalid_key => "foo")
      end.to raise_error(ArgumentError, "invalid keys: invalid_key")
    end
  end

  describe "self.create" do
    it "raises an exception if hash includes an invalid key" do
      expect do
        Braintree::Transaction.create(:amount => "Joe", :invalid_key => "foo")
      end.to raise_error(ArgumentError, "invalid keys: invalid_key")
    end
  end

  describe "self.find" do
    it "raises error if passed empty string" do
      expect do
        Braintree::Transaction.find("")
      end.to raise_error(ArgumentError, "id can not be empty")
    end

    it "raises error if passed empty string wth space" do
      expect do
        Braintree::Transaction.find(" ")
      end.to raise_error(ArgumentError, "id can not be empty")
    end

    it "raises error if passed nil" do
      expect do
        Braintree::Transaction.find(nil)
      end.to raise_error(ArgumentError, "id can not be empty")
    end
  end

  describe "self.submit_for_settlement" do
    it "raises an ArgumentError if transaction_id is an invalid format" do
      expect do
        Braintree::Transaction.submit_for_settlement("invalid-transaction-id")
      end.to raise_error(ArgumentError, "transaction_id is invalid")
    end
  end

  describe "self.adjust_authorization" do
    it "raises an ArgumentError if transaction_id is an invalid format" do
      expect do
        Braintree::Transaction.adjust_authorization("invalid-transaction-id", "10.00")
      end.to raise_error(ArgumentError, "transaction_id is invalid")
    end
  end

  describe "self.update_details" do
    it "raises an ArgumentError if transaction_id is an invalid format" do
      expect do
        Braintree::Transaction.update_details("invalid-transaction-id")
      end.to raise_error(ArgumentError, "transaction_id is invalid")
    end
  end

  describe "initialize" do
    it "sets up customer attributes in customer_details" do
      transaction = Braintree::Transaction._new(
        :gateway,
        :customer => {
          :id => "123",
          :first_name => "Adam",
          :last_name => "Taylor",
          :company => "Ledner LLC",
          :email => "adam.taylor@lednerllc.com",
          :website => "lednerllc.com",
          :phone => "1-999-652-4189 x56883",
          :fax => "012-161-8055"
        },
      )
      expect(transaction.customer_details.id).to eq("123")
      expect(transaction.customer_details.first_name).to eq("Adam")
      expect(transaction.customer_details.last_name).to eq("Taylor")
      expect(transaction.customer_details.company).to eq("Ledner LLC")
      expect(transaction.customer_details.email).to eq("adam.taylor@lednerllc.com")
      expect(transaction.customer_details.website).to eq("lednerllc.com")
      expect(transaction.customer_details.phone).to eq("1-999-652-4189 x56883")
      expect(transaction.customer_details.fax).to eq("012-161-8055")
    end

    it "sets up disbursement attributes in disbursement_details" do
      transaction = Braintree::Transaction._new(
        :gateway,
        :disbursement_details => {
          :disbursement_date => "2013-04-03",
          :settlement_amount => "120.00",
          :settlement_currency_iso_code => "USD",
          :settlement_currency_exchange_rate => "1",
          :funds_held => false,
          :success => true
        },
      )
      disbursement = transaction.disbursement_details
      expect(disbursement.disbursement_date).to eq(Date.parse("2013-04-03"))
      expect(disbursement.settlement_amount).to eq("120.00")
      expect(disbursement.settlement_currency_iso_code).to eq("USD")
      expect(disbursement.settlement_currency_exchange_rate).to eq("1")
      expect(disbursement.funds_held?).to be(false)
      expect(disbursement.success?).to be(true)
    end

    it "sets up credit card attributes in credit_card_details" do
      transaction = Braintree::Transaction._new(
        :gateway,
        :credit_card => {
          :token => "mzg2",
          :bin => "411111",
          :last_4 => "1111",
          :card_type => "Visa",
          :expiration_month => "08",
          :expiration_year => "2009",
          :customer_location => "US",
          :prepaid => "Yes",
          :healthcare => "Yes",
          :durbin_regulated => "Yes",
          :debit => "Yes",
          :commercial => "No",
          :payroll => "Unknown",
          :product_id => "Unknown",
          :country_of_issuance => "Narnia",
          :issuing_bank => "Mr Tumnus"
        },
      )
      expect(transaction.credit_card_details.token).to eq("mzg2")
      expect(transaction.credit_card_details.bin).to eq("411111")
      expect(transaction.credit_card_details.last_4).to eq("1111")
      expect(transaction.credit_card_details.card_type).to eq("Visa")
      expect(transaction.credit_card_details.expiration_month).to eq("08")
      expect(transaction.credit_card_details.expiration_year).to eq("2009")
      expect(transaction.credit_card_details.customer_location).to eq("US")
      expect(transaction.credit_card_details.prepaid).to eq(Braintree::CreditCard::Prepaid::Yes)
      expect(transaction.credit_card_details.healthcare).to eq(Braintree::CreditCard::Healthcare::Yes)
      expect(transaction.credit_card_details.durbin_regulated).to eq(Braintree::CreditCard::DurbinRegulated::Yes)
      expect(transaction.credit_card_details.debit).to eq(Braintree::CreditCard::Debit::Yes)
      expect(transaction.credit_card_details.commercial).to eq(Braintree::CreditCard::Commercial::No)
      expect(transaction.credit_card_details.payroll).to eq(Braintree::CreditCard::Payroll::Unknown)
      expect(transaction.credit_card_details.product_id).to eq(Braintree::CreditCard::ProductId::Unknown)
      expect(transaction.credit_card_details.country_of_issuance).to eq("Narnia")
      expect(transaction.credit_card_details.issuing_bank).to eq("Mr Tumnus")
    end

    it "sets up network token attributes in network_token_details" do
      transaction = Braintree::Transaction._new(
        :gateway,
        :network_token => {
          :token => "mzg2",
          :bin => "411111",
          :last_4 => "1111",
          :card_type => "Visa",
          :expiration_month => "08",
          :expiration_year => "2009",
          :customer_location => "US",
          :prepaid => "Yes",
          :healthcare => "Yes",
          :durbin_regulated => "Yes",
          :debit => "Yes",
          :commercial => "No",
          :payroll => "Unknown",
          :product_id => "Unknown",
          :country_of_issuance => "Narnia",
          :issuing_bank => "Mr Tumnus",
          :is_network_tokenized => true
        },
      )
      expect(transaction.network_token_details.token).to eq("mzg2")
      expect(transaction.network_token_details.bin).to eq("411111")
      expect(transaction.network_token_details.last_4).to eq("1111")
      expect(transaction.network_token_details.card_type).to eq("Visa")
      expect(transaction.network_token_details.expiration_month).to eq("08")
      expect(transaction.network_token_details.expiration_year).to eq("2009")
      expect(transaction.network_token_details.customer_location).to eq("US")
      expect(transaction.network_token_details.prepaid).to eq(Braintree::CreditCard::Prepaid::Yes)
      expect(transaction.network_token_details.healthcare).to eq(Braintree::CreditCard::Healthcare::Yes)
      expect(transaction.network_token_details.durbin_regulated).to eq(Braintree::CreditCard::DurbinRegulated::Yes)
      expect(transaction.network_token_details.debit).to eq(Braintree::CreditCard::Debit::Yes)
      expect(transaction.network_token_details.commercial).to eq(Braintree::CreditCard::Commercial::No)
      expect(transaction.network_token_details.payroll).to eq(Braintree::CreditCard::Payroll::Unknown)
      expect(transaction.network_token_details.product_id).to eq(Braintree::CreditCard::ProductId::Unknown)
      expect(transaction.network_token_details.country_of_issuance).to eq("Narnia")
      expect(transaction.network_token_details.issuing_bank).to eq("Mr Tumnus")
      expect(transaction.network_token_details.is_network_tokenized?).to eq(true)
    end

    it "sets up three_d_secure_info" do
      transaction = Braintree::Transaction._new(
        :gateway,
        :three_d_secure_info => {
          :enrolled => "Y",
          :liability_shifted => true,
          :liability_shift_possible => true,
          :status => "authenticate_successful",
        },
      )

      expect(transaction.three_d_secure_info.enrolled).to eq("Y")
      expect(transaction.three_d_secure_info.status).to eq("authenticate_successful")
      expect(transaction.three_d_secure_info.liability_shifted).to eq(true)
      expect(transaction.three_d_secure_info.liability_shift_possible).to eq(true)
    end

    it "sets up history attributes in status_history" do
      time = Time.utc(2010,1,14)
      transaction = Braintree::Transaction._new(
        :gateway,
        :status_history => [
          {:timestamp => time, :amount => "12.00", :transaction_source => "API",
            :user => "larry", :status => Braintree::Transaction::Status::Authorized},
          {:timestamp => Time.utc(2010,1,15), :amount => "12.00", :transaction_source => "API",
            :user => "curly", :status => "scheduled_for_settlement"}
        ])
      expect(transaction.status_history.size).to eq(2)
      expect(transaction.status_history[0].user).to eq("larry")
      expect(transaction.status_history[0].amount).to eq("12.00")
      expect(transaction.status_history[0].status).to eq(Braintree::Transaction::Status::Authorized)
      expect(transaction.status_history[0].transaction_source).to eq("API")
      expect(transaction.status_history[0].timestamp).to eq(time)
      expect(transaction.status_history[1].user).to eq("curly")
    end

    it "sets up authorization_adjustments" do
      timestamp = Time.utc(2010,1,14)
      transaction = Braintree::Transaction._new(
        :gateway,
        :authorization_adjustments => [
          {:timestamp => timestamp, :processor_response_code => "1000", :processor_response_text => "Approved", :amount => "12.00", :success => true},
          {:timestamp => timestamp, :processor_response_code => "3000", :processor_response_text => "Processor Network Unavailable - Try Again", :amount => "12.34", :success => false},
        ])
      expect(transaction.authorization_adjustments.size).to eq(2)
      expect(transaction.authorization_adjustments[0].amount).to eq("12.00")
      expect(transaction.authorization_adjustments[0].success).to eq(true)
      expect(transaction.authorization_adjustments[0].timestamp).to eq(timestamp)
      expect(transaction.authorization_adjustments[0].processor_response_code).to eq("1000")
      expect(transaction.authorization_adjustments[0].processor_response_text).to eq("Approved")
      expect(transaction.authorization_adjustments[1].amount).to eq("12.34")
      expect(transaction.authorization_adjustments[1].success).to eq(false)
      expect(transaction.authorization_adjustments[1].timestamp).to eq(timestamp)
      expect(transaction.authorization_adjustments[1].processor_response_code).to eq("3000")
      expect(transaction.authorization_adjustments[1].processor_response_text).to eq("Processor Network Unavailable - Try Again")
    end

    it "accepts retry_ids and retried_transaction_id attributes in a transactions" do
      transaction = Braintree::Transaction._new(
        :gateway,
        :retry_ids => ["retry_id_1"],
        :retried_transaction_id => "original_retried_tranction_id",
      )
      expect(transaction.retry_ids.count).to eq(1)
      expect(transaction.retry_ids[0]).to eq("retry_id_1")
      expect(transaction.retried_transaction_id).to eq("original_retried_tranction_id")
    end

    it "handles receiving custom as an empty string" do
      transaction = Braintree::Transaction._new(
        :gateway,
        :custom => "\n    ",
      )
    end

    it "accepts amount as either a String or a BigDecimal" do
      expect(Braintree::Transaction._new(:gateway, :amount => "12.34").amount).to eq(BigDecimal("12.34"))
      expect(Braintree::Transaction._new(:gateway, :amount => BigDecimal("12.34")).amount).to eq(BigDecimal("12.34"))
    end

    it "blows up if amount is not a string or BigDecimal" do
      expect {
        Braintree::Transaction._new(:gateway, :amount => 12.34)
      }.to raise_error(/Argument must be a String or BigDecimal/)
    end

    it "handles nil risk_data" do
      transaction = Braintree::Transaction._new(
        :gateway,
        :risk_data => nil,
      )
      expect(transaction.risk_data).to be_nil
    end

    it "accepts network_transaction_id" do
      transaction = Braintree::Transaction._new(
        :gateway,
        :network_transaction_id => "123456789012345",
      )
      expect(transaction.network_transaction_id).to eq("123456789012345")
    end

    it "accepts ach_return_code" do
      transaction = Braintree::Transaction._new(
        :gateway,
        :ach_return_code => "R01",
      )
      expect(transaction.ach_return_code).to eq("R01")
    end

    it "accepts network_response code and network_response_text" do
      transaction = Braintree::Transaction._new(
        :gateway,
        :network_response_code => "00",
        :network_response_text => "Successful approval/completion or V.I.P. PIN verification is successful",
      )
      expect(transaction.network_response_code).to eq("00")
      expect(transaction.network_response_text).to eq("Successful approval/completion or V.I.P. PIN verification is successful")
    end

    it "accepts merchant_advice_code and merchant_advice_text" do
      transaction = Braintree::Transaction._new(
        :gateway,
        :merchant_advice_code => "01",
        :merchant_advice_code_text => "New account information available",
      )
      expect(transaction.merchant_advice_code).to eq("01")
      expect(transaction.merchant_advice_code_text).to eq("New account information available")
    end

    it "accepts sepa_direct_debit_return_code" do
      transaction = Braintree::Transaction._new(
        :gateway,
        :sepa_direct_debit_return_code => "AM04",
      )
      expect(transaction.sepa_direct_debit_return_code).to eq("AM04")
    end

    it "accepts sepa_direct_debit_account_details" do
      transaction = Braintree::Transaction._new(
        :gateway,
        :id => "123",
        :type => "sale",
        :amount => "12.34",
        :status => "settled",
        :sepa_debit_account_detail => {
          :token => "1234",
        },
      )
      details = transaction.sepa_direct_debit_account_details
      expect(details.token).to eq("1234")
    end

    it "accepts debit_network" do
      transaction = Braintree::Transaction._new(
        :gateway,
        :debit_network => "STAR",
      )
      expect(transaction.debit_network).to eq "STAR"
    end
  end

  describe "inspect" do
    it "includes the id, type, amount, status, and processed_with_network_token?" do
      transaction = Braintree::Transaction._new(
        :gateway,
        :id => "1234",
        :type => "sale",
        :amount => "100.00",
        :status => Braintree::Transaction::Status::Authorized,
        :processed_with_network_token => false,
      )
      output = transaction.inspect
      expect(output).to include(%Q(#<Braintree::Transaction id: "1234", type: "sale", amount: "100.0", status: "authorized"))
      expect(output).to include(%Q(processed_with_network_token?: false))
    end
  end

  describe "==" do
    it "returns true for transactions with the same id" do
      first = Braintree::Transaction._new(:gateway, :id => 123)
      second = Braintree::Transaction._new(:gateway, :id => 123)

      expect(first).to eq(second)
      expect(second).to eq(first)
    end

    it "returns false for transactions with different ids" do
      first = Braintree::Transaction._new(:gateway, :id => 123)
      second = Braintree::Transaction._new(:gateway, :id => 124)

      expect(first).not_to eq(second)
      expect(second).not_to eq(first)
    end

    it "returns false when comparing to nil" do
      expect(Braintree::Transaction._new(:gateway, {})).not_to eq(nil)
    end

    it "returns false when comparing to non-transactions" do
      same_id_different_object = Object.new
      def same_id_different_object.id; 123; end
      transaction = Braintree::Transaction._new(:gateway, :id => 123)
      expect(transaction).not_to eq(same_id_different_object)
    end
  end

  describe "new" do
    it "is protected" do
      expect do
        Braintree::Transaction.new
      end.to raise_error(NoMethodError, /protected method .new/)
    end
  end

  describe "refunded?" do
    it "is true if the transaciton has been refunded" do
      transaction = Braintree::Transaction._new(:gateway, :refund_id => "123")
      expect(transaction.refunded?).to eq(true)
    end

    it "is false if the transaciton has not been refunded" do
      transaction = Braintree::Transaction._new(:gateway, :refund_id => nil)
      expect(transaction.refunded?).to eq(false)
    end
  end

  describe "sale" do
    let(:mock_response) { {:transaction => {}} }
    let(:http_stub) { double("http_stub").as_null_object }

    RSpec::Matchers.define :skip_advanced_fraud_check_value_is do |value|
        match { |params| params[:transaction][:options][:skip_advanced_fraud_checking] == value }
    end

    it "accepts skip_advanced_fraud_checking options with value true" do
      allow(Braintree::Http).to receive(:new).and_return http_stub
      expect(http_stub).to receive(:post).with(anything, skip_advanced_fraud_check_value_is(true)).and_return(mock_response)

      Braintree::Transaction.sale(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
        :options => {
          :skip_advanced_fraud_checking => true
        },
      )
    end

    it "accepts skip_advanced_fraud_checking options with value false" do
      allow(Braintree::Http).to receive(:new).and_return http_stub
      expect(http_stub).to receive(:post).with(anything, skip_advanced_fraud_check_value_is(false)).and_return(mock_response)

      Braintree::Transaction.sale(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
        :options => {
          :skip_advanced_fraud_checking => false
        },
      )
    end

    it "doesn't include skip_advanced_fraud_checking in params if its not specified" do
      allow(Braintree::Http).to receive(:new).and_return http_stub
      expect(http_stub).to receive(:post).with(anything, skip_advanced_fraud_check_value_is(nil)).and_return(mock_response)

      Braintree::Transaction.sale(
        :amount => Braintree::Test::TransactionAmounts::Authorize,
        :credit_card => {
          :number => Braintree::Test::CreditCardNumbers::Visa,
          :expiration_date => "05/2009"
        },
        :options => {
          :submit_for_settlement => false
        },
      )
    end
  end

  describe "processed_with_network_token?" do
    it "is true if the transaction was processed with a network token" do
      transaction = Braintree::Transaction._new(:gateway, :processed_with_network_token => true)
      expect(transaction.processed_with_network_token?).to eq(true)
    end

    it "is false if the transaction was not processed with a network token" do
      transaction = Braintree::Transaction._new(:gateway, :processed_with_network_token => false)
      expect(transaction.processed_with_network_token?).to eq(false)
    end
  end

  describe "gateway rejection reason" do
    it "verifies excessive_retry mapping" do
      transaction = Braintree::Transaction._new(:gateway, :gateway_rejection_reason => "excessive_retry")
      expect(transaction.gateway_rejection_reason).to eq(Braintree::Transaction::GatewayRejectionReason::ExcessiveRetry)
    end
  end
end
