require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::PayPalAccount do
  describe "self.find" do
    it "returns a PayPalAccount" do
      customer = Braintree::Customer.create!
      payment_method_token = random_payment_method_token

      nonce = nonce_for_paypal_account(
        :consent_code => "consent-code",
        :token => payment_method_token,
      )
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
      )
      expect(result).to be_success

      paypal_account = Braintree::PayPalAccount.find(payment_method_token)
      expect(paypal_account).to be_a(Braintree::PayPalAccount)
      expect(paypal_account.token).to eq(payment_method_token)
      expect(paypal_account.email).to eq("jane.doe@example.com")
      expect(paypal_account.image_url).not_to be_nil
      expect(paypal_account.created_at).not_to be_nil
      expect(paypal_account.updated_at).not_to be_nil
      expect(paypal_account.customer_id).to eq(customer.id)
      expect(paypal_account.revoked_at).to be_nil
    end

    it "returns a PayPalAccount with a billing agreement id" do
      customer = Braintree::Customer.create!
      payment_method_token = random_payment_method_token

      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => Braintree::Test::Nonce::PayPalBillingAgreement,
        :customer_id => customer.id,
        :token => payment_method_token,
      )
      expect(result).to be_success

      paypal_account = Braintree::PayPalAccount.find(payment_method_token)
      expect(paypal_account.billing_agreement_id).not_to be_nil
    end

    it "raises if the payment method token is not found" do
      expect do
        Braintree::PayPalAccount.find("nonexistant-paypal-account")
      end.to raise_error(Braintree::NotFoundError)
    end

    it "does not return a different payment method type" do
      customer = Braintree::Customer.create!
      Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2009",
        :cvv => "100",
        :token => "CREDIT_CARD_TOKEN",
      )

      expect do
        Braintree::PayPalAccount.find("CREDIT_CARD_TOKEN")
      end.to raise_error(Braintree::NotFoundError)
    end

    it "returns subscriptions associated with a paypal account" do
      customer = Braintree::Customer.create!
      payment_method_token = random_payment_method_token

      nonce = nonce_for_paypal_account(
        :consent_code => "consent-code",
        :token => payment_method_token,
      )
      result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
      )
      expect(result).to be_success

      token = result.payment_method.token

      subscription1 = Braintree::Subscription.create(
        :payment_method_token => token,
        :plan_id => SpecHelper::TriallessPlan[:id],
      ).subscription

      subscription2 = Braintree::Subscription.create(
        :payment_method_token => token,
        :plan_id => SpecHelper::TriallessPlan[:id],
      ).subscription

      paypal_account = Braintree::PayPalAccount.find(token)
      expect(paypal_account.subscriptions.map(&:id).sort).to eq([subscription1.id, subscription2.id].sort)
    end
  end

  describe "self.create" do
    it "creates a PayPalAccount" do
      customer = Braintree::Customer.create!
      result = Braintree::PayPalAccount.create(
        :customer_id => customer.id,
        :billing_agreement_id => "some_billing_agreement_id",
        :email => "some@example.com",
        :options => {
            :make_default => true,
            :fail_on_duplicate_payment_method => true,
        },
      )

      expect(result).to be_success
      expect(result.paypal_account.billing_agreement_id).to eq("some_billing_agreement_id")
      expect(result.paypal_account.email).to eq("some@example.com")
    end

    it "throws an error if customer id is not specified" do
      result = Braintree::PayPalAccount.create(
        :billing_agreement_id => "some_billing_agreement_id",
        :email => "some@example.com",
      )

      expect(result.success?).to eq(false)
      expect(result.errors.first.code).to eq("82905")
    end

    it "throws an error if billing agreement id is not specified" do
      customer = Braintree::Customer.create!
      result = Braintree::PayPalAccount.create(
        :customer_id => customer.id,
        :email => "some@example.com",
      )

      expect(result.success?).to eq(false)
      expect(result.errors.map(&:code)).to include("82902")
    end
  end

  describe "self.update" do
    it "updates a PayPalAccount" do
      customer = Braintree::Customer.create!
      create_result = Braintree::PayPalAccount.create(
        :customer_id => customer.id,
        :billing_agreement_id => "first_billing_agreement_id",
        :email => "first@example.com",
      )
      expect(create_result.success?).to eq(true)

      update_result = Braintree::PayPalAccount.update(
        create_result.paypal_account.token,
        :billing_agreement_id => "second_billing_agreement_id",
        :email => "second@example.com",
      )

      expect(update_result.success?).to eq(true)
      paypal_account = update_result.paypal_account

      expect(paypal_account.billing_agreement_id).to eq("second_billing_agreement_id")
      expect(paypal_account.email).to eq("second@example.com")
    end

    it "updates a paypal account's token" do
      customer = Braintree::Customer.create!
      original_token = random_payment_method_token
      nonce = nonce_for_paypal_account(
        :consent_code => "consent-code",
        :token => original_token,
      )
      original_result = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
      )

      updated_token = "UPDATED_TOKEN-" + rand(36**3).to_s(36)
      Braintree::PayPalAccount.update(
        original_token,
        :token => updated_token,
      )

      updated_paypal_account = Braintree::PayPalAccount.find(updated_token)
      expect(updated_paypal_account.email).to eq(original_result.payment_method.email)

      expect do
        Braintree::PayPalAccount.find(original_token)
      end.to raise_error(Braintree::NotFoundError, "payment method with token \"#{original_token}\" not found")
    end

    it "can make a paypal account the default payment method" do
      customer = Braintree::Customer.create!
      result = Braintree::CreditCard.create(
        :customer_id => customer.id,
        :number => Braintree::Test::CreditCardNumbers::Visa,
        :expiration_date => "05/2009",
        :options => {:make_default => true},
      )
      expect(result).to be_success

      nonce = nonce_for_paypal_account(:consent_code => "consent-code")
      original_token = Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
      ).payment_method.token

      Braintree::PayPalAccount.update(
        original_token,
        :options => {:make_default => true},
      )

      updated_paypal_account = Braintree::PayPalAccount.find(original_token)
      expect(updated_paypal_account).to be_default
    end

    it "returns an error if a token for account is used to attempt an update" do
      customer = Braintree::Customer.create!
      first_token = random_payment_method_token
      second_token = random_payment_method_token

      first_nonce = nonce_for_paypal_account(
        :consent_code => "consent-code",
        :token => first_token,
      )
      Braintree::PaymentMethod.create(
        :payment_method_nonce => first_nonce,
        :customer_id => customer.id,
      )

      second_nonce = nonce_for_paypal_account(
        :consent_code => "consent-code",
        :token => second_token,
      )
      Braintree::PaymentMethod.create(
        :payment_method_nonce => second_nonce,
        :customer_id => customer.id,
      )

      updated_result = Braintree::PayPalAccount.update(
        first_token,
        :token => second_token,
      )

      expect(updated_result).not_to be_success
      expect(updated_result.errors.first.code).to eq("92906")
    end
  end

  context "self.delete" do
    it "deletes a PayPal account" do
      customer = Braintree::Customer.create!
      token = random_payment_method_token

      nonce = nonce_for_paypal_account(
        :consent_code => "consent-code",
        :token => token,
      )
      Braintree::PaymentMethod.create(
        :payment_method_nonce => nonce,
        :customer_id => customer.id,
      )

      Braintree::PayPalAccount.delete(token)

      expect do
        Braintree::PayPalAccount.find(token)
      end.to raise_error(Braintree::NotFoundError, "payment method with token \"#{token}\" not found")
    end
  end

  context "self.sale" do
    it "creates a transaction using a paypal account and returns a result object" do
      customer = Braintree::Customer.create!(
        :payment_method_nonce => Braintree::Test::Nonce::PayPalBillingAgreement,
      )

      result = Braintree::PayPalAccount.sale(customer.paypal_accounts[0].token, :amount => "100.00")

      expect(result.success?).to eq(true)
      expect(result.transaction.amount).to eq(BigDecimal("100.00"))
      expect(result.transaction.type).to eq("sale")
      expect(result.transaction.customer_details.id).to eq(customer.id)
      expect(result.transaction.paypal_details.token).to eq(customer.paypal_accounts[0].token)
    end
  end

  context "self.sale!" do
    it "creates a transaction using a paypal account and returns a transaction" do
      customer = Braintree::Customer.create!(
        :payment_method_nonce => Braintree::Test::Nonce::PayPalBillingAgreement,
      )

      transaction = Braintree::PayPalAccount.sale!(customer.paypal_accounts[0].token, :amount => "100.00")

      expect(transaction.amount).to eq(BigDecimal("100.00"))
      expect(transaction.type).to eq("sale")
      expect(transaction.customer_details.id).to eq(customer.id)
      expect(transaction.paypal_details.token).to eq(customer.paypal_accounts[0].token)
    end
  end
end
