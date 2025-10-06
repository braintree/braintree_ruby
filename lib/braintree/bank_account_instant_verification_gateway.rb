module Braintree
  class BankAccountInstantVerificationGateway

    CREATE_JWT_MUTATION =
      "mutation CreateBankAccountInstantVerificationJwt($input: CreateBankAccountInstantVerificationJwtInput!) { " +
      "  createBankAccountInstantVerificationJwt(input: $input) {" +
      "    jwt" +
      "  }" +
      "}"

    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def create_jwt(request)
      variables = request.to_graphql_variables
      response = @gateway.graphql_client.query(CREATE_JWT_MUTATION, variables)
      errors = Braintree::GraphQLClient.get_validation_errors(response)

      if errors
        ErrorResult.new(@gateway, {errors: errors})
      else
        data = response.dig(:data, :createBankAccountInstantVerificationJwt)

        if data.nil?
          raise UnexpectedError, "expected :createBankAccountInstantVerificationJwt"
        end

        jwt_attrs = {
          :jwt => data[:jwt]
        }

        SuccessfulResult.new(:bank_account_instant_verification_jwt => BankAccountInstantVerificationJwt._new(jwt_attrs))
      end
    end
  end
end