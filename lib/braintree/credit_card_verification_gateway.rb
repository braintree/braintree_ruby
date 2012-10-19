module Braintree
  class CreditCardVerificationGateway
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
    end

    def find(id)
      raise ArgumentError if id.nil? || id.strip.to_s == ""
      response = @config.http.get "/verifications/#{id}"
      CreditCardVerification._new(response[:verification])
    rescue NotFoundError
      raise NotFoundError, "verification with id #{id.inspect} not found"
    end

    def search(&block)
      search = CreditCardVerificationSearch.new
      block.call(search) if block

      response = @config.http.post "/verifications/advanced_search_ids", {:search => search.to_hash}
      ResourceCollection.new(response) { |ids| _fetch_verifications(search, ids) }
    end

    def _fetch_verifications(search, ids)
      search.ids.in ids
      response = @config.http.post "/verifications/advanced_search", {:search => search.to_hash}
      attributes = response[:credit_card_verifications]
      Util.extract_attribute_as_array(attributes, :verification).map { |attrs| CreditCardVerification._new(attrs) }
    end
  end
end
