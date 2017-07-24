module Braintree
  class DisputeGateway # :nodoc:
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
      @config.assert_has_access_token_or_keys
    end

    def find(dispute_id)
      raise ArgumentError, "dispute_id contains invalid characters" unless dispute_id.to_s =~ /\A[\w-]+\z/
      raise ArgumentError, "dispute_id cannot be blank" if dispute_id.nil? || dispute_id.to_s.strip == ""
      response = @config.http.get("#{@config.base_merchant_path}/disputes/#{dispute_id}")
      Dispute._new(response[:dispute])
    rescue NotFoundError
      raise NotFoundError, "dispute with id #{dispute_id.inspect} not found"
    end

    def search(&block)
      search = DisputeSearch.new
      block.call(search) if block

      pc = PaginatedCollection.new { |page| _fetch_disputes(search, page) }
      SuccessfulResult.new(:disputes => pc)
    end

    def _fetch_disputes(search, page)
      response = @config.http.post("#{@config.base_merchant_path}/disputes/advanced_search?page=#{page}", {:search => search.to_hash, :page => page})
      body = response[:disputes]
      disputes = Util.extract_attribute_as_array(body, :dispute).map { |d| Dispute._new(d) }

      PaginatedResult.new(body[:total_items], body[:page_size], disputes)
    end
  end
end
