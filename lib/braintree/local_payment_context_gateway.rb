module Braintree
  class LocalPaymentContextGateway
    CREATE_LOCAL_PAYMENT_CONTEXT = <<~GRAPHQL
      mutation CreateLocalPaymentContext($input: CreateLocalPaymentContextInput!) {
        createLocalPaymentContext(input: $input) {
          paymentContext {
            id
            legacyId
            type
            paymentId
            approvalUrl
            merchantAccountId
            orderId
            createdAt
            transactedAt
            approvedAt
            amount {
              value
              currencyCode
            }
          }
        }
      }
    GRAPHQL

    FIND_LOCAL_PAYMENT_CONTEXT = <<~GRAPHQL
      query Node($id: ID!) {
        node(id: $id) {
          ... on LocalPaymentContext {
            id
            legacyId
            type
            amount {
              value
              currencyIsoCode
            }
            approvalUrl
            merchantAccountId
            transactedAt
            approvedAt
            createdAt
            updatedAt
            expiredAt
            paymentId
            orderId
          }
        }
      }
    GRAPHQL

    def initialize(gateway, graphql_client)
      @gateway = gateway
      @graphql_client = graphql_client
    end

    def create(input)
      variables = {"input" => input.to_graphql_variables}

      begin
        response = @graphql_client.query(CREATE_LOCAL_PAYMENT_CONTEXT, variables)
        errors = GraphQLClient.get_validation_errors(response)

        if errors
          ErrorResult.new(@gateway, {errors: errors})
        else
          payment_context = extract_payment_context(response)
          SuccessfulResult.new(:payment_context => payment_context)
        end
      rescue StandardError => e
        raise UnexpectedError, e.message
      end
    end

    def find(id)
      variables = {"id" => id}

      begin
        response = @graphql_client.query(FIND_LOCAL_PAYMENT_CONTEXT, variables)
        errors = GraphQLClient.get_validation_errors(response)

        if errors
          ErrorResult.new(@gateway, {errors: errors})
        else
          payment_context = extract_node_payment_context(response)
          SuccessfulResult.new(:payment_context => payment_context)
        end
      rescue NotFoundError
        raise
      rescue StandardError => e
        raise UnexpectedError, e.message
      end
    end

    private

    def extract_payment_context(response)
      context_hash = get_value(response, "data.createLocalPaymentContext.paymentContext")
      LocalPaymentContext._new({:response => {"paymentContext" => context_hash}})
    end

    def extract_node_payment_context(response)
      node_hash = get_value(response, "data.node")

      if node_hash.nil?
        raise NotFoundError, "Payment context not found"
      end

      LocalPaymentContext._new({:response => {"paymentContext" => node_hash}})
    end

    def get_value(response, key)
      map = response
      key_parts = key.split(".")

      key_parts[0..-2].each do |sub_key|
        map = pop_value(map, sub_key)
        raise UnexpectedError, "Couldn't parse response" unless map.is_a?(Hash)
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
  end
end
