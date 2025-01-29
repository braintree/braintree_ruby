require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/client_api/spec_helper")

describe Braintree::CustomerSessionGateway do
  let(:gateway) do
    Braintree::Gateway.new(
      :environment => :development,
      :merchant_id => "pwpp_multi_account_merchant",
      :public_key => "pwpp_multi_account_merchant_public_key",
      :private_key => "pwpp_multi_account_merchant_private_key",
    )
  end

  describe "create" do
    it "can create customer session without email and phone" do
      input = Braintree::CreateCustomerSessionInput.new(merchant_account_id: "usd_pwpp_multi_account_merchant_account")
      result = gateway.customer_session.create_customer_session(input)
      expect(result.success?).to eq(true)
      expect(result.session_id).not_to be_nil
    end

    it "can can create customer session with merchant provided session id" do
      merchant_session_id = "11EF-A1E7-A5F5EE5C-A2E5-AFD2801469FC"
      input = Braintree::CreateCustomerSessionInput.new(
        session_id: merchant_session_id,
      )
      result = gateway.customer_session.create_customer_session(input)
      expect(result.success?).to eq(true)
      expect(result.session_id).to eq(merchant_session_id)
    end

    it "can create customer session with API-derived session id" do
      input = Braintree::CreateCustomerSessionInput.new({})
      result = gateway.customer_session.create_customer_session(input)
      expect(result.success?).to eq(true)
      expect(result.session_id).not_to be_nil
    end

    it "cannot create duplicate customer session" do
      existing_session_id = "11EF-34BC-2702904B-9026-C3ECF4BAC765"
      input = Braintree::CreateCustomerSessionInput.new(
        session_id: existing_session_id,
      )
      result = gateway.customer_session.create_customer_session(input)
      expect(result.success?).to eq(false)
      expect(result.errors.first.message).to include("Session IDs must be unique per merchant.")
    end
  end

  describe "update" do
    it "can update a customer session" do
      session_id = "11EF-A1E7-A5F5EE5C-A2E5-AFD2801469FC"
      create_input = Braintree::CreateCustomerSessionInput.new(
        merchant_account_id: "usd_pwpp_multi_account_merchant_account",
        session_id: session_id,
      )

      gateway.customer_session.create_customer_session(create_input)

      customer = build_customer_session_input("PR5_test@example.com", "4085005005")

      update_input = Braintree::UpdateCustomerSessionInput.new(
        session_id: session_id,
        customer: customer,
      )

      result = gateway.customer_session.update_customer_session(update_input)

      expect(result.success?).to eq(true)
      expect(result.session_id).to eq(session_id)

    end

    it "cannot update a non-existent customer session" do
      session_id = "11EF-34BC-2702904B-9026-C3ECF4BAC765"
      customer = build_customer_session_input("PR9_test@example.com", "4085005009")
      update_input = Braintree::UpdateCustomerSessionInput.new(
        session_id: session_id,
        customer: customer,
      )

      result = gateway.customer_session.update_customer_session(update_input)

      expect(result.success?).to eq(false)
      expect(result.errors.first.message).to include("does not exist")
    end
  end

  describe "customer recommendations" do
    it "can get customer recommendations" do
      customer = build_customer_session_input("PR5_test@example.com", "4085005005")
      recommendations = [Braintree::Recommendations::PAYMENT_RECOMMENDATIONS]
      customer_recommendations_input = Braintree::CustomerRecommendationsInput.new(
        session_id: "11EF-A1E7-A5F5EE5C-A2E5-AFD2801469FC",
        recommendations: recommendations,
        customer: customer,
      )
      result = gateway.customer_session.get_customer_recommendations(customer_recommendations_input)

      expect(result.success?).to eq(true)
      payload = result.customer_recommendations
      expect(payload.is_in_paypal_network).to eq(true)
      payment_options = payload.recommendations.payment_options
      expect(payment_options[0].payment_option).to eq(Braintree::RecommendedPaymentOption::PAYPAL)
      expect(payment_options[0].recommended_priority).to equal(1)
    end

    it "cannot get customer recommendations for non-existent session" do
      customer = build_customer_session_input("PR9_test@example.com", "4085005009")
      recommendations = [Braintree::Recommendations::PAYMENT_RECOMMENDATIONS]
      customer_recommendations_input = Braintree::CustomerRecommendationsInput.new(
        session_id: "11EF-34BC-2702904B-9026-C3ECF4BAC765",
        recommendations: recommendations,
        customer: customer,
      )
      result = gateway.customer_session.get_customer_recommendations(customer_recommendations_input)

      expect(result.success?).to eq(false)
      expect(result.errors.first.message).to include("does not exist")
    end
  end

  private

  def build_customer_session(session_id = nil)
    customer = build_customer_session_input("PR1_test@example.com", "4085005002")

    input = session_id ? CreateCustomerSessionInput.new(customer: customer, session_id: session_id) : CreateCustomerSessionInput.new(customer => customer)
    @gateway.customer_session.create_customer_session(input)
  end

  def build_customer_session_input(email, phone_number)
    {
      email: email,
      device_fingerprint_id: "test",
      phone: {country_phone_code: "1", phone_number: phone_number},
      paypal_app_installed: true,
      venmo_app_installed: true,
      user_agent: "Mozilla"
    }
  end

end
