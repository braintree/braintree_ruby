require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe "Coinbase" do

  def assert_valid_coinbase_attrs(account_or_details)
    [:user_id, :user_name, :user_email].each do |attr|
      [nil,""].should_not include(account_or_details.send(attr))
    end
  end

  it "works for transaction#create" do
    result = Braintree::Transaction.sale(:payment_method_nonce => Braintree::Test::Nonce::Coinbase, :amount => "0.02")
    result.should be_success
    assert_valid_coinbase_attrs(result.transaction.coinbase_details)
  end

  it "works for vaulting" do
    customer = Braintree::Customer.create!
    vaulted = Braintree::PaymentMethod.create(:customer_id => customer.id, :payment_method_nonce => Braintree::Test::Nonce::Coinbase).payment_method
    assert_valid_coinbase_attrs(vaulted)

    found = Braintree::PaymentMethod.find(vaulted.token).payment_method
    assert_valid_coinbase_attrs(found)
  end

  it "is returned on Customers" do
    customer = Braintree::Customer.create!(:payment_method_nonce => Braintree::Test::Nonce::Coinbase)
    customer.payment_methods.should == customer.coinbase_accounts
    assert_valid_coinbase_attrs(customer.coinbase_accounts[0])
  end
end
