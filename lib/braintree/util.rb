module Braintree
  module Util # :nodoc:
    def self.extract_attribute_as_array(hash, attribute)
      raise UnexpectedError.new("Unprocessable entity due to an invalid request") if hash.nil?
      value = hash.has_key?(attribute) ? hash.delete(attribute) : []
      value.is_a?(Array) ? value : [value]
    end

    def self.hash_to_query_string(hash, namespace = nil)
      hash.collect do |key, value|
        full_key = namespace ? "#{namespace}[#{key}]" : key
        if value.is_a?(Hash)
          hash_to_query_string(value, full_key)
        else
          url_encode(full_key) + "=" + url_encode(value)
        end
      end.sort * '&'
    end

    def self.parse_query_string(qs)
      qs.split('&').inject({}) do |result, couplet|
        pair = couplet.split('=')
        result[CGI.unescape(pair[0]).to_sym] = CGI.unescape(pair[1])
        result
      end
    end

    def self.url_encode(text)
      CGI.escape text.to_s
    end

    def self.symbolize_keys(hash)
      hash.inject({}) do |new_hash, (key, value)|
        if value.is_a?(Hash)
          value = symbolize_keys(value)
        elsif value.is_a?(Array) && value.all? { |v| v.is_a?(Hash) }
          value = value.map { |v| symbolize_keys(v) }
        end

        new_hash.merge(key.to_sym => value)
      end
    end

    def self.raise_exception_for_status_code(status_code, message=nil)
      case status_code.to_i
      when 401
        raise AuthenticationError
      when 403
        raise AuthorizationError, message
      when 404
        raise NotFoundError
      when 426
        raise UpgradeRequiredError, "Please upgrade your client library."
      when 500
        raise ServerError
      when 503
        raise DownForMaintenanceError
      else
        raise UnexpectedError, "Unexpected HTTP_RESPONSE #{status_code.to_i}"
      end
    end

    def self.to_big_decimal(decimal)
      case decimal
      when BigDecimal, NilClass
        decimal
      when String
        BigDecimal.new(decimal)
      else
        raise ArgumentError, "Argument must be a String or BigDecimal"
      end
    end

    def self.verify_keys(valid_keys, hash)
      flattened_valid_keys = _flatten_valid_keys(valid_keys)
      invalid_keys = _flatten_hash_keys(hash) - flattened_valid_keys
      invalid_keys = _remove_wildcard_keys(flattened_valid_keys, invalid_keys)
      if invalid_keys.any?
        sorted = invalid_keys.sort_by { |k| k.to_s }.join(", ")
        raise ArgumentError, "invalid keys: #{sorted}"
      end
    end

    def self._flatten_valid_keys(valid_keys, namespace = nil)
      valid_keys.inject([]) do |result, key|
        if key.is_a?(Hash)
          full_key = key.keys[0]
          full_key = (namespace ? "#{namespace}[#{full_key}]" : full_key)
          nested_keys = key.values[0]
          if nested_keys.is_a?(Array)
            result += _flatten_valid_keys(nested_keys, full_key)
          else
            result << "#{full_key}[#{nested_keys}]"
          end
        else
          result << (namespace ? "#{namespace}[#{key}]" : key.to_s)
        end
        result
      end.sort
    end

    def self._flatten_hash_keys(hash, namespace = nil)
      hash.inject([]) do |result, (key, value)|
        full_key = (namespace ? "#{namespace}[#{key}]" : key.to_s)
        if value.is_a?(Hash)
          result += _flatten_hash_keys(value, full_key)
        elsif value.is_a?(Array)
          value.each do |item|
            result += _flatten_hash_keys(item, full_key)
          end
        else
          result << full_key
        end
        result
      end.sort
    end

    def self._remove_wildcard_keys(valid_keys, invalid_keys)
      wildcard_keys = valid_keys.select { |k| k.include? "[_any_key_]" }
      return invalid_keys if wildcard_keys.empty?
      wildcard_keys.map! { |wk| wk.sub "[_any_key_]", "" }
      invalid_keys.select do |invalid_key|
        wildcard_keys.all? do |wildcard_key|
          invalid_key.index(wildcard_key) != 0
        end
      end
    end
  end
end
