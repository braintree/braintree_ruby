require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Braintree::CustomerSessionGateway do
  let(:gateway) { double(:gateway) }
  let(:graphql_client) { double(:graphql_client) }
  let(:customer_session_gateway) { Braintree::CustomerSessionGateway.new(gateway, graphql_client) }

  describe "#create_customer_session" do
    let(:input) do
      {
       :merchant_account_id => "merchant-account-id",
      }
    end

    let(:response) do
        {
          data: {
            createCustomerSession: {
                sessionId: "session-id"
            }
          }
        }
    end


    it "executes the createCustomerSession mutation" do
      create_input = Braintree::CreateCustomerSessionInput.new(input)
      expect(graphql_client).to receive(:query).with(Braintree::CustomerSessionGateway::CREATE_CUSTOMER_SESSION,
      {
        "input" => create_input.to_graphql_variables
      }).and_return(response)

      expect(Braintree::GraphQLClient).to receive(:get_validation_errors).with(response).and_return(nil)
      result = customer_session_gateway.create_customer_session(create_input)
      expect(result).to be_a(Braintree::SuccessfulResult)
      expect(result.session_id).to eq("session-id")
    end

    it "returns an error result if there are validation errors" do
      create_input = Braintree::CreateCustomerSessionInput.new(input)
      errors = {:errors =>
        [ {:attribute => "", :code => "123", :message => "error"} ]
      }
      expect(graphql_client).to receive(:query).and_return(response)
      expect(Braintree::GraphQLClient).to receive(:get_validation_errors).with(response).and_return(errors)
      result = customer_session_gateway.create_customer_session(create_input)
      expect(result).to be_a(Braintree::ErrorResult)
      expect(result.errors.first.message).to eq("error")
    end

    it "raises an UnexpectedError if there is a problem parsing the response" do
      create_input = Braintree::CreateCustomerSessionInput.new(input)
      badResonse =  {:data => {}}
      expect(graphql_client).to receive(:query).and_return(badResonse)
      expect(Braintree::GraphQLClient).to receive(:get_validation_errors).with(badResonse).and_return(nil)
      expect { customer_session_gateway.create_customer_session(create_input) }.to raise_error(Braintree::UnexpectedError)
    end
  end


  describe "#update_customer_session" do
      let(:input) do
        {
          :merchant_account_id => "merchant-account-id", :session_id => "session-id"
        }
      end
      let(:response) do
        {
          data: {
            updateCustomerSession: {
                sessionId: "session-id"
            }
          }
        }
      end

      it "executes the updateCustomerSession mutation" do
        update_input = Braintree::UpdateCustomerSessionInput.new(input)
        expect(graphql_client).to receive(:query).with(Braintree::CustomerSessionGateway::UPDATE_CUSTOMER_SESSION,
        {
          "input" => update_input.to_graphql_variables
        }).and_return(response)
        expect(Braintree::GraphQLClient).to receive(:get_validation_errors).with(response).and_return(nil)
        result = customer_session_gateway.update_customer_session(update_input)
        expect(result).to be_a(Braintree::SuccessfulResult)
        expect(result.session_id).to eq("session-id")
      end
  end

  describe "#get_customer_recommendations" do
    let(:customer_recommendations_input) { double(:customer_recommendations_input, to_graphql_variables: {"sessionId" => "session_id", recommendations: ["PAYMENT_RECOMMENDATIONS"]}) }
    let(:response) do
      {
        data: {
          customerRecommendations: {
              isInPayPalNetwork: true,
              recommendations: {
                paymentOptions: [
                  {paymentOption: "PAYPAL", recommendedPriority: 1}
                ]
              }
          }
        }
      }
    end

    it "fetches customer recommendations" do
      expected_variables = {"input" => {"sessionId" => "session_id", recommendations: ["PAYMENT_RECOMMENDATIONS"]}}
      expect(graphql_client).to receive(:query).with(Braintree::CustomerSessionGateway::GET_CUSTOMER_RECOMMENDATIONS, expected_variables).and_return(response)
      expect(Braintree::GraphQLClient).to receive(:get_validation_errors).with(response).and_return(nil)

      result = customer_session_gateway.get_customer_recommendations(customer_recommendations_input)
      expect(result).to be_a(Braintree::SuccessfulResult)
      expect(result.customer_recommendations.is_in_paypal_network).to eq(true)
      expect(result.customer_recommendations.recommendations.payment_options[0].payment_option).to eq("PAYPAL")
      expect(result.customer_recommendations.recommendations.payment_options[0].recommended_priority).to eq(1)
    end
  end

end
