module Braintree
  class GraphQLClient < Http # :nodoc:

    def initialize(config)
      @config = config
      @graphql_headers = {
        'Accept' => 'application/json',
        'Braintree-Version' => @config.graphql_api_version,
        'Content-Type' => 'application/json'
      }
    end

    def query(definition, variables = {}, operationName = nil)
      graphql_connection = _setup_connection(@config.graphql_server, @config.graphql_port)

      request = {}
      request['query'] = definition
      request['operationName'] = operationName if operationName
      request['variables'] = variables

      response = _http_do Net::HTTP::Post, @config.graphql_base_url, request.to_json, nil, graphql_connection, @graphql_headers
      data = JSON.parse(response.body, :symbolize_names => true)
      Util.raise_exception_for_graphql_error(data)

      data
    end
  end
end
