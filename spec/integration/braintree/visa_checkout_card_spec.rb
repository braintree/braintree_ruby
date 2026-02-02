require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

# DEPRECATED: Visa Checkout is no longer supported for creating new transactions.
# Search functionality is retained for historical transactions only.
describe Braintree::VisaCheckoutCard do
  it "can search by payment instrument type" do
    search_results = Braintree::Transaction.search do |search|
      search.payment_instrument_type.is Braintree::PaymentInstrumentType::VisaCheckoutCard
    end

    expect(search_results).not_to be_nil
  end
end
