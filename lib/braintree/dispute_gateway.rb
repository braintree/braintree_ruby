module Braintree
  class DisputeGateway # :nodoc:
    def initialize(gateway)
      @gateway = gateway
      @config = gateway.config
      @config.assert_has_access_token_or_keys
    end

    def accept(dispute_id)
      raise ArgumentError, "dispute_id contains invalid characters" unless dispute_id.to_s =~ /\A[\w-]+\z/
      raise ArgumentError, "dispute_id cannot be blank" if dispute_id.nil? || dispute_id.to_s.strip == ""

      response = @config.http.put("#{@config.base_merchant_path}/disputes/#{dispute_id}/accept")
      if response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        SuccessfulResult.new
      end
    rescue NotFoundError
      raise NotFoundError, "dispute with id #{dispute_id} not found"
    end

    def add_text_evidence(dispute_id, content)
      raise ArgumentError, "dispute_id contains invalid characters" unless dispute_id.to_s =~ /\A[\w-]+\z/
      raise ArgumentError, "dispute_id cannot be blank" if dispute_id.nil? || dispute_id.to_s.strip == ""
      raise ArgumentError, "content cannot be blank" if content.nil? || content.to_s.strip == ""

      params = {comments: content}
      response = @config.http.post("#{@config.base_merchant_path}/disputes/#{dispute_id}/evidence", params)

      if response[:evidence]
        SuccessfulResult.new(:evidence => Dispute::Evidence.new(response[:evidence]))
      elsif response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        raise "expected :evidence or :api_error_response"
      end
    rescue NotFoundError
      raise NotFoundError, "dispute with id #{dispute_id} not found"
    end

    def finalize(dispute_id)
      raise ArgumentError, "dispute_id contains invalid characters" unless dispute_id.to_s =~ /\A[\w-]+\z/
      raise ArgumentError, "dispute_id cannot be blank" if dispute_id.nil? || dispute_id.to_s.strip == ""

      response = @config.http.put("#{@config.base_merchant_path}/disputes/#{dispute_id}/finalize")
      if response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        SuccessfulResult.new
      end
    rescue NotFoundError
      raise NotFoundError, "dispute with id #{dispute_id} not found"
    end

    def find(dispute_id)
      raise ArgumentError, "dispute_id contains invalid characters" unless dispute_id.to_s =~ /\A[\w-]+\z/
      raise ArgumentError, "dispute_id cannot be blank" if dispute_id.nil? || dispute_id.to_s.strip == ""
      response = @config.http.get("#{@config.base_merchant_path}/disputes/#{dispute_id}")
      Dispute._new(response[:dispute])
    rescue NotFoundError
      raise NotFoundError, "dispute with id #{dispute_id} not found"
    end

    def remove_evidence(dispute_id, evidence_id)
      raise ArgumentError, "dispute_id contains invalid characters" unless dispute_id.to_s =~ /\A[\w-]+\z/
      raise ArgumentError, "dispute_id cannot be blank" if dispute_id.nil? || dispute_id.to_s.strip == ""
      raise ArgumentError, "evidence_id contains invalid characters" unless evidence_id.to_s =~ /\A[\w-]+\z/
      raise ArgumentError, "evidence_id cannot be blank" if evidence_id.nil? || evidence_id.to_s.strip == ""

      response = @config.http.delete("#{@config.base_merchant_path}/disputes/#{dispute_id}/evidence/#{evidence_id}")

      if response.respond_to?(:to_hash) && response[:api_error_response]
        ErrorResult.new(@gateway, response[:api_error_response])
      else
        SuccessfulResult.new
      end
    rescue NotFoundError
      raise NotFoundError, "evidence with id #{evidence_id} for dispute with id #{dispute_id} not found"
    end

    def search(&block)
      search = DisputeSearch.new
      block.call(search) if block

      paginated_results = PaginatedCollection.new { |page| _fetch_disputes(search, page) }
      SuccessfulResult.new(:disputes => paginated_results)
    end

    def _fetch_disputes(search, page)
      response = @config.http.post("#{@config.base_merchant_path}/disputes/advanced_search?page=#{page}", {:search => search.to_hash, :page => page})
      body = response[:disputes]
      disputes = Util.extract_attribute_as_array(body, :dispute).map { |d| Dispute._new(d) }

      PaginatedResult.new(body[:total_items], body[:page_size], disputes)
    end
  end
end
