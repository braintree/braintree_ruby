require File.dirname(__FILE__) + "/../spec_helper"

describe Braintree::TransparentRedirect do
  it "raises a DownForMaintenanceError when app is in maintenance mode on TR requests" do
    tr_data = Braintree::TransparentRedirect.create_customer_data({:redirect_url => "http://example.com"}.merge({}))
    query_string_response = SpecHelper.simulate_form_post_for_tr(tr_data, {}, Braintree::Configuration.base_merchant_url + "/test/maintenance")
    expect do
      Braintree::Customer.create_from_transparent_redirect(query_string_response)
    end.to raise_error(Braintree::DownForMaintenanceError)
  end

  it "raises an AuthenticationError when authentication fails on TR requests" do
    SpecHelper.using_configuration(:private_key => "incorrect") do
      tr_data = Braintree::TransparentRedirect.create_customer_data({:redirect_url => "http://example.com"}.merge({}))
      query_string_response = SpecHelper.simulate_form_post_for_tr(tr_data, {}, Braintree::Customer.create_customer_url)
      expect do
        Braintree::Customer.create_from_transparent_redirect(query_string_response)
      end.to raise_error(Braintree::AuthenticationError)
    end
  end

  describe "self.confirm" do
    it "successfully confirms a transaction create" do
      params = {
        :transaction => {
          :amount => Braintree::Test::TransactionAmounts::Authorize,
          :credit_card => {
            :number => Braintree::Test::CreditCardNumbers::Visa,
            :expiration_date => "05/2009"
          }
        }
      }
      tr_data_params = {
        :transaction => {
          :type => "sale"
        }
      }
      tr_data = Braintree::TransparentRedirect.transaction_data({:redirect_url => "http://example.com"}.merge(tr_data_params))
      query_string_response = SpecHelper.simulate_form_post_for_tr(tr_data, params)
      result = Braintree::TransparentRedirect.confirm(query_string_response)

      result.success?.should == true
      transaction = result.transaction
      transaction.type.should == "sale"
      transaction.amount.should == BigDecimal.new("1000.00")
      transaction.credit_card_details.bin.should == Braintree::Test::CreditCardNumbers::Visa[0, 6]
      transaction.credit_card_details.last_4.should == Braintree::Test::CreditCardNumbers::Visa[-4..-1]
      transaction.credit_card_details.expiration_date.should == "05/2009"
    end
  end
end
