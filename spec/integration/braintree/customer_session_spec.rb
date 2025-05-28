require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::CustomerSessionGateway do
  let(:pwpp_gateway) do
    Braintree::Gateway.new(
      :environment => :development,
      :merchant_id => "pwpp_multi_account_merchant",
      :public_key => "pwpp_multi_account_merchant_public_key",
      :private_key => "pwpp_multi_account_merchant_private_key",
    )
  end

  describe "create" do
    it "can create customer session without email and phone" do
      input = Braintree::CreateCustomerSessionInput.new(
        merchant_account_id: "usd_pwpp_multi_account_merchant_account",
      )
      result = pwpp_gateway.customer_session.create_customer_session(input)
      expect(result.success?).to eq(true)
      expect(result.session_id).not_to be_nil
    end

    it "can create customer session with merchant provided session id" do
      merchant_session_id = "11EF-A1E7-A5F5EE5C-A2E5-AFD2801469FC"
      input = Braintree::CreateCustomerSessionInput.new(
        session_id: merchant_session_id,
      )
      result = pwpp_gateway.customer_session.create_customer_session(input)
      expect(result.success?).to eq(true)
      expect(result.session_id).to eq(merchant_session_id)
    end

    it "can create customer session with API-derived session id" do
      result = build_customer_session(nil)
      expect(result.session_id).not_to be_nil
    end

    it "can create customer session with purchase units" do
      input = Braintree::CreateCustomerSessionInput.new(
        purchase_units: build_purchase_units,
      )
      result = pwpp_gateway.customer_session.create_customer_session(input)
      expect(result.success?).to eq(true)
      expect(result.session_id).not_to be_nil
    end

    it "cannot create duplicate customer session" do
      existing_session_id = "11EF-34BC-2702904B-9026-C3ECF4BAC765"
      result = build_customer_session(existing_session_id)
      expect(result.success?).to eq(false)
      expect(result.errors.first.message).to include("Session IDs must be unique per merchant")
    end
  end

  describe "update" do
    it "can update a customer session" do
      session_id = "11EF-A1E7-A5F5EE5C-A2E5-AFD2801469FC"
      create_input = Braintree::CreateCustomerSessionInput.new(
        merchant_account_id: "usd_pwpp_multi_account_merchant_account",
        session_id: session_id,
        purchase_units: build_purchase_units,
      )
      pwpp_gateway.customer_session.create_customer_session(create_input)

      customer = build_customer_session_input
      update_input = Braintree::UpdateCustomerSessionInput.new(
        session_id: session_id,
        customer: customer,
      )
      result = pwpp_gateway.customer_session.update_customer_session(update_input)

      expect(result.success?).to eq(true)
      expect(result.session_id).to eq(session_id)
    end

    it "cannot update a non-existent customer session" do
      session_id = "11EF-34BC-2702904B-9026-C3ECF4BAC765"
      customer = build_customer_session_input
      update_input = Braintree::UpdateCustomerSessionInput.new(
        session_id: session_id,
        customer: customer,
      )
      result = pwpp_gateway.customer_session.update_customer_session(update_input)

      expect(result.success?).to eq(false)
      expect(result.errors.first.message).to include("does not exist")
    end
  end

  describe "customer recommendations" do
    it "can get customer recommendations" do
      customer = build_customer_session_input
      customer_recommendations_input = Braintree::CustomerRecommendationsInput.new(
        session_id: "94f0b2db-5323-4d86-add3-paypal000000",
        customer: customer,
        purchase_units: build_purchase_units,
        domain: "domain.com",
      )

      result = pwpp_gateway.customer_session.get_customer_recommendations(customer_recommendations_input)

      expect(result.success?).to eq(true)
      payload = result.customer_recommendations
      expect(payload.is_in_paypal_network).to eq(true)

      recommendation = payload.recommendations.payment_recommendations[0]
      expect(recommendation.payment_option).to eq(Braintree::RecommendedPaymentOption::PAYPAL)
      expect(recommendation.recommended_priority).to eq(1)
    end

    it "raises an error when not authorized" do
      customer = build_customer_session_input
      customer_recommendations_input = Braintree::CustomerRecommendationsInput.new(
        session_id: "6B29FC40-CA47-1067-B31D-00DD010662DA",
        customer: customer,
        purchase_units: build_purchase_units,
        domain: "domain.com",
        merchant_account_id: "gbp_pwpp_multi_account_merchant_account",
      )

      expect {
        pwpp_gateway.customer_session.get_customer_recommendations(customer_recommendations_input)
      }.to raise_error(Braintree::AuthorizationError)
    end
  end

  private

  def build_customer_session(session_id = nil)
    customer = build_customer_session_input
    input_attributes = {customer: customer}
    input_attributes[:session_id] = session_id if session_id

    input = Braintree::CreateCustomerSessionInput.new(input_attributes)
    pwpp_gateway.customer_session.create_customer_session(input)
  end

  def build_customer_session_input
    {
      hashed_email: "48ddb93f0b30c475423fe177832912c5bcdce3cc72872f8051627967ef278e08",
      hashed_phone_number: "a2df2987b2a3384210d3aa1c9fb8b627ebdae1f5a9097766c19ca30ec4360176",
      device_fingerprint_id: "00DD010662DE",
      user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/x.x.x.x Safari/537.36",
    }
  end

  def build_purchase_units
    amount = {currency_code: "USD", value: "10.00"}
    purchase_unit = {amount: amount}
    [purchase_unit]
  end
end