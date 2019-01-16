require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::IdealPayment do
  context "self.sale" do
    it "creates a transaction using an Ideal payment token and returns a result object" do
      ideal_payment_id = generate_valid_ideal_payment_nonce

      result = Braintree::IdealPayment.sale(
        ideal_payment_id,
        :order_id => SpecHelper::DefaultOrderId,
        :merchant_account_id => "ideal_merchant_account",
        :amount => Braintree::Test::TransactionAmounts::Authorize
      )

      result.success?.should == true
      result.transaction.amount.should == BigDecimal(Braintree::Test::TransactionAmounts::Authorize)
      result.transaction.type.should == "sale"
      ideal_payment_details = result.transaction.ideal_payment_details
      ideal_payment_details.ideal_payment_id.should =~ /^idealpayment_\w{6,}$/
      ideal_payment_details.ideal_transaction_id.should =~ /^\d{16,}$/
      ideal_payment_details.image_url.should start_with("https://")
      ideal_payment_details.masked_iban.should_not be_empty
      ideal_payment_details.bic.should_not be_empty
    end
  end

  context "self.sale!" do
    it "creates a transaction using an ideal payment and returns a result object" do
      ideal_payment_id = generate_valid_ideal_payment_nonce

      transaction = Braintree::IdealPayment.sale!(
        ideal_payment_id,
        :order_id => SpecHelper::DefaultOrderId,
        :merchant_account_id => "ideal_merchant_account",
        :amount => Braintree::Test::TransactionAmounts::Authorize
      )

      transaction.amount.should == BigDecimal(Braintree::Test::TransactionAmounts::Authorize)
      transaction.type.should == "sale"
      ideal_payment_details = transaction.ideal_payment_details
      ideal_payment_details.ideal_payment_id.should =~ /^idealpayment_\w{6,}$/
      ideal_payment_details.ideal_transaction_id.should =~ /^\d{16,}$/
      ideal_payment_details.image_url.should start_with("https://")
      ideal_payment_details.masked_iban.should_not be_empty
      ideal_payment_details.bic.should_not be_empty
    end

    it "does not create a transaction using an ideal payment and returns raises an exception" do
      expect do
        Braintree::IdealPayment.sale!(
          "invalid_nonce",
          :merchant_account_id => "ideal_merchant_account",
          :amount => Braintree::Test::TransactionAmounts::Authorize
        )
      end.to raise_error(Braintree::ValidationsFailed)
    end
  end

  context "self.find" do
    it "finds the Ideal payment with an id" do
      ideal_payment_id = generate_valid_ideal_payment_nonce
      ideal_payment = Braintree::IdealPayment.find(ideal_payment_id)

      ideal_payment.id.should =~ /^idealpayment_\w{6,}$/
      ideal_payment.ideal_transaction_id.should =~ /^\d{16,}$/
      ideal_payment.currency.should_not be_empty
      ideal_payment.amount.should_not be_empty
      ideal_payment.status.should_not be_empty
      ideal_payment.order_id.should_not be_empty
      ideal_payment.issuer.should_not be_empty
      ideal_payment.approval_url.should start_with("https://")
      ideal_payment.iban_bank_account.account_holder_name.should_not be_empty
      ideal_payment.iban_bank_account.bic.should_not be_empty
      ideal_payment.iban_bank_account.masked_iban.should_not be_empty
      ideal_payment.iban_bank_account.iban_account_number_last_4.should =~ /^\d{4}$/
      ideal_payment.iban_bank_account.iban_country.should_not be_empty
      ideal_payment.iban_bank_account.description.should_not be_empty
    end

    it "raises if the Ideal payment is not found" do
      expect do
        Braintree::IdealPayment.find("idealpayment_nxyqkq_s654wq_92jr64_mnr4kr_yjz")
      end.to raise_error(Braintree::NotFoundError)
    end
  end
end
