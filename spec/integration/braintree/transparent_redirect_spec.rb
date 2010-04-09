require File.dirname(__FILE__) + "/../spec_helper"

describe Braintree::TransparentRedirect do
  it "raises a DownForMaintenanceError when app is in maintenance mode on TR requests" do
    tr_data = Braintree::TransparentRedirect.create_customer_data({:redirect_url => "http://example.com"}.merge({}))
    query_string_response = SpecHelper.simulate_form_post_for_tr(Braintree::Configuration.base_merchant_url + "/test/maintenance", tr_data, {})
    expect do
      Braintree::Customer.create_from_transparent_redirect(query_string_response)
    end.to raise_error(Braintree::DownForMaintenanceError)
  end

  it "raises an AuthenticationError when authentication fails on TR requests" do
    SpecHelper.using_configuration(:private_key => "incorrect") do
      tr_data = Braintree::TransparentRedirect.create_customer_data({:redirect_url => "http://example.com"}.merge({}))
      query_string_response = SpecHelper.simulate_form_post_for_tr(Braintree::Customer.create_customer_url, tr_data, {})
      expect do
        Braintree::Customer.create_from_transparent_redirect(query_string_response)
      end.to raise_error(Braintree::AuthenticationError)
    end
  end
end
