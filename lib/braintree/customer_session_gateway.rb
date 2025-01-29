# Creates and manages PayPal customer sessions.

module Braintree
    class CustomerSessionGateway
      CREATE_CUSTOMER_SESSION = <<~GRAPHQL
        mutation CreateCustomerSession($input: CreateCustomerSessionInput!) {
          createCustomerSession(input: $input) {
            sessionId
          }
        }
      GRAPHQL

      UPDATE_CUSTOMER_SESSION = <<~GRAPHQL
        mutation UpdateCustomerSession($input: UpdateCustomerSessionInput!) {
          updateCustomerSession(input: $input) {
            sessionId
          }
        }
      GRAPHQL

      GET_CUSTOMER_RECOMMENDATIONS = <<~GRAPHQL
        query CustomerRecommendations($input: CustomerRecommendationsInput!) {
          customerRecommendations(input: $input) {
            isInPayPalNetwork
            recommendations {
              ... on PaymentRecommendations {
                paymentOptions {
                  paymentOption
                  recommendedPriority
                }
              }
            }
          }
        }
      GRAPHQL

      def initialize(gateway, graphql_client)
        @gateway = gateway
        @graphql_client = graphql_client
      end

      # Creates a new customer session.
      #
      # Example:
      #   customer = {
      #    email: "test@example.com",
      #    device_fingerprint_id: "1234",
      #    phone: {country_phone_code: "1", phone_number: "5555555555"},
      #    paypal_app_installed: true,
      #    venmo_app_installed: true,
      #   }
      #   input = Braintree::CreateCustomerSessionInput.new(
      #                customer: customer,
      #   )
      #   result = gateway.customer_session.create_customer_session(input)
      #   if result.success?
      #     puts "Created session #{result.session_id}"
      #   else
      #     puts "Validations failed"
      #     puts result.errors.first.message
      #   end
      #
      # @param input [CreateCustomerSessionInput] The input parameters for creating a customer session.
      #
      # @return [(Successful|Error)Result] A result object with session ID if successful, or errors otherwise.
      #
      # @raise [UnexpectedError] If there is an unexpected error during the process.
      def create_customer_session(input)
        execute_mutation(CREATE_CUSTOMER_SESSION, input, :createCustomerSession)
      end


      # Updates an existing customer session.
      #
      # Example:
      #   customer = {
      #    email: "test@example.com",
      #    device_fingerprint_id: "1234",
      #    phone: {country_phone_code: "1", phone_number: "5555555555"},
      #    paypal_app_installed: true,
      #    venmo_app_installed: true,
      #   }
      #   input = Braintree::UpdateCustomerSessionInput.new(
      #                session_id: "11EF-34BC-2702904B-9026-555555555555",
      #                customer: customer,
      #   )
      #   result = gateway.customer_session.updated_customer_session(input)
      #   if result.success?
      #     puts "Updated session #{result.session_id}"
      #   else
      #     puts "Validations failed"
      #     puts result.errors.first.message
      #   end
      #
      # @param input [UpdateCustomerSessionInput] The input parameters for updating a customer session.
      #
      # @return [(Successful|Error)Result] A result object with session ID if successful, or errors otherwise.
      #
      # @raise [UnexpectedError] If there is an unexpected error during the process.
      def update_customer_session(input)
        execute_mutation(UPDATE_CUSTOMER_SESSION, input, :updateCustomerSession)
      end

      # Retrieves customer recommendations associated with a customer session.
      #
      # Example:
      #   customer = {
      #    email: "test@example.com",
      #    device_fingerprint_id: "1234",
      #    phone: {country_phone_code: "1", phone_number: "5555555555"},
      #    paypal_app_installed: true,
      #    venmo_app_installed: true,
      #   }
      #   input = Braintree::CustomerRecommendationsInput.new(
      #                session_id: "11EF-34BC-2702904B-9026-555555555555",
      #                customer: customer,
      #                recommendations: [Braintree::Recommendations::PAYMENT_RECOMMENDATIONS]
      #   )
      #   result = gateway.customer_session.get_customer_recommendations(input)
      #   if result.success?
      #     puts "Fetched customer recommendations"
      #     payload = result.customer_recommendations
      #     puts payload
      #   else
      #     puts "Validations failed"
      #     puts result.errors.first.message
      #   end
      #
      # @param input [CustomerRecommendationsInput] The input parameters for retrieving customer recommendations.
      #
      # @return [Result\Error|Result\Successful] A result object containing the customer recommendations if successful, or errors otherwise.
      #
      # @raise [UnexpectedError] If there is an unexpected error during the process.
      def get_customer_recommendations(customer_recommendations_input)
        variables = {"input" => customer_recommendations_input.to_graphql_variables}

        begin
          response = @graphql_client.query(GET_CUSTOMER_RECOMMENDATIONS, variables)
          errors = GraphQLClient.get_validation_errors(response)
          if errors
            ErrorResult.new(@gateway, {errors:errors})
          else
            SuccessfulResult.new(:customer_recommendations => extract_customer_recommendations_payload(response))
          end
        rescue StandardError => e
          raise UnexpectedError, e.message
        end
      end

      private

      def execute_mutation(query, input, operation_name)
        variables = {"input" => input.to_graphql_variables}
        begin
          response = @graphql_client.query(query, variables)
          errors = GraphQLClient.get_validation_errors(response)
          if errors
            ErrorResult.new(@gateway, {errors:errors})
          else
            session_id = get_value(response, "data.#{operation_name}.sessionId")
            SuccessfulResult.new(:session_id => session_id)
          end
        rescue StandardError => e
          raise UnexpectedError, e.message
        end
      end

      def get_value(response, key)
        map = response
        key_parts = key.split(".")

        key_parts[0..-2].each do |sub_key|
          map = pop_value(map, sub_key)
          raise UnexpectedError, "Couldn't parse response"  unless map.is_a?(Hash)
        end

        pop_value(map, key_parts.last)
      end

      def pop_value(map, key)
        key = key.to_sym
        if map.key?(key)
          map[key]
        else
          raise UnexpectedError, "Couldn't parse response"
        end
      end

      def extract_customer_recommendations_payload(data)
        customer_recommendations_hash = get_value(data, "data.customerRecommendations")
        Braintree::CustomerRecommendationsPayload._new(customer_recommendations_hash)
      end
    end
  end
